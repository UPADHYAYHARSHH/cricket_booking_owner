import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/location_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/owner_repository.dart';
import 'package:turfpro_owner/common/constants/fee_constants.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final OwnerRepository _ownerRepository;
  final BookingRepository _bookingRepository;
  final LocationRepository _locationRepository;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  String? _selectedLocationId;

  DashboardCubit(
    this._ownerRepository,
    this._bookingRepository,
    this._locationRepository,
  ) : super(DashboardInitial()) {
    _selectedLocationId = SharedPrefsService.instance.selectedLocationId;
  }

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchDashboardData() async {
    _selectedLocationId = SharedPrefsService.instance.selectedLocationId;
    emit(DashboardLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(DashboardError('User not logged in'));
        return;
      }

      final ownerData = await _ownerRepository.getOwnerDetails(user.uid);
      if (ownerData == null) {
        emit(DashboardError('Owner details not found'));
        return;
      }

      final ownerName = ownerData['owner_name'] ?? 'Owner';
      final venueName = ownerData['venue_name'] ?? 'Your Venue';

      final locations = await _locationRepository.getOwnerLocations(user.uid);

      // Each row in `grounds` is one physical court, so the count of grounds
      // scoped to the selected location IS the active-courts count for it.
      final allGroundsData = await _bookingRepository.getOwnerGrounds(user.uid);
      final groundsData = _selectedLocationId == null
          ? allGroundsData
          : allGroundsData
              .where((g) => g['location_id'] == _selectedLocationId)
              .toList();
      final int courts = groundsData.length;

      if (groundsData.isEmpty) {
        emit(DashboardLoaded(
          ownerName: ownerName,
          venueName: venueName,
          activeCourts: 0,
          todayRevenue: '₹0',
          revenueChangeLabel: '—',
          todayBookingsCount: 0,
          pendingAcceptCount: 0,
          occupancyPercentage: '0%',
          locations: locations,
          selectedLocationId: _selectedLocationId,
        ));
        return;
      }

      final groundIds = groundsData.map((g) => g['id'] as Object).toList();
      final groundMap = {for (var g in groundsData) g['id']: g['name']};

      await _bookingsSubscription?.cancel();
      _bookingsSubscription = _bookingRepository
          .watchBookingsForGrounds(groundIds)
          .listen((bookings) async {
        double todayRevenue = 0;
        double yesterdayRevenue = 0;
        int todayBookingsCount = 0;
        int pendingAcceptCount = 0;
        final List<dynamic> todaySlots = [];
        final List<dynamic> pendingApprovals = [];

        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        for (var b in bookings) {
          final status = b['status']?.toString().toLowerCase() ?? '';
          final bookingDateStr = b['slot_time'] ?? b['created_at'];

          if (bookingDateStr != null) {
            try {
              final bDate = DateTime.parse(bookingDateStr).toLocal();
              final isRevenueCounted = b['user_id'] != null && (status == 'confirmed' || status == 'completed' || status == 'paid');
              final gross = (b['amount'] ?? b['total_amount'] ?? 0).toDouble();
              final commissionFee = kCommissionIsPercentage
                  ? gross * kCommissionRate / 100
                  : kCommissionRate;
              final amount = (gross - kPlatformFee - commissionFee).clamp(0.0, double.infinity);

              if (bDate.year == now.year &&
                  bDate.month == now.month &&
                  bDate.day == now.day) {
                todayBookingsCount++;
                if (isRevenueCounted) {
                  todayRevenue += amount;
                }
                todaySlots.add({
                  ...b,
                  'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
                });
              } else if (bDate.year == yesterday.year &&
                  bDate.month == yesterday.month &&
                  bDate.day == yesterday.day &&
                  isRevenueCounted) {
                yesterdayRevenue += amount;
              }
            } catch (_) {}
          }

          if (status == 'pending') {
            pendingAcceptCount++;
            pendingApprovals.add({
              ...b,
              'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
            });
          }
        }

        // Resolve customer names for today's slots so the dashboard can show
        // who booked, not just the raw user id.
        final todayUserIds = todaySlots
            .map((s) => (s as Map)['user_id'])
            .where((id) => id != null)
            .cast<String>()
            .toSet()
            .toList();
        final users = todayUserIds.isEmpty
            ? <Map<String, dynamic>>[]
            : await _bookingRepository.fetchUsers(todayUserIds);
        final userMap = {for (var u in users) u['id']: u};
        final enrichedTodaySlots = todaySlots.map((slot) {
          final s = slot as Map<String, dynamic>;
          final userData = userMap[s['user_id']];
          final uidStr = s['user_id']?.toString() ?? '';
          return <String, dynamic>{
            ...s,
            'player_name': userData?['full_name'] ??
                userData?['name'] ??
                'Customer (ID: ${uidStr.length > 4 ? uidStr.substring(0, 4) : uidStr})',
          };
        }).toList();

        final occupancy = courts > 0
            ? '${(todayBookingsCount / (courts * 10) * 100).clamp(0, 100).toInt()}%'
            : '0%';

        String revenueChangeLabel;
        if (yesterdayRevenue <= 0) {
          revenueChangeLabel = todayRevenue > 0 ? 'New today' : '—';
        } else {
          final change = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
          final sign = change >= 0 ? '+' : '';
          revenueChangeLabel = '$sign${change.toInt()}%';
        }

        emit(DashboardLoaded(
          ownerName: ownerName,
          venueName: venueName,
          activeCourts: courts,
          todayRevenue: '₹${todayRevenue.toInt()}',
          revenueChangeLabel: revenueChangeLabel,
          todayBookingsCount: todayBookingsCount,
          pendingAcceptCount: pendingAcceptCount,
          occupancyPercentage: occupancy,
          todaySlots: enrichedTodaySlots,
          pendingApprovals: pendingApprovals,
          locations: locations,
          selectedLocationId: _selectedLocationId,
        ));
      });
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void selectLocation(String? locationId) {
    if (locationId == _selectedLocationId) return;
    _selectedLocationId = locationId;
    SharedPrefsService.instance.setSelectedLocationId(locationId);
    fetchDashboardData();
  }
}
