import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/owner_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final OwnerRepository _ownerRepository;
  final BookingRepository _bookingRepository;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  DashboardCubit(this._ownerRepository, this._bookingRepository)
      : super(DashboardInitial());

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchDashboardData() async {
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

      int activeCourts = 0;
      final groundConfig = ownerData['ground_config'] as Map<String, dynamic>?;
      if (groundConfig != null) {
        groundConfig.forEach((_, sportDetails) {
          if (sportDetails is Map<String, dynamic>) {
            final numCourts = sportDetails['num_courts'];
            if (numCourts is int) {
              activeCourts += numCourts;
            } else if (numCourts is String) {
              activeCourts += int.tryParse(numCourts) ?? 0;
            }
          }
        });
      }

      final groundsData = await _bookingRepository.getOwnerGrounds(user.uid);
      if (groundsData.isEmpty) {
        emit(DashboardLoaded(
          ownerName: ownerName,
          venueName: venueName,
          activeCourts: activeCourts > 0 ? activeCourts : 3,
          todayRevenue: '₹0',
          todayBookingsCount: 0,
          pendingAcceptCount: 0,
          occupancyPercentage: '0%',
        ));
        return;
      }

      final groundIds = groundsData.map((g) => g['id'] as Object).toList();
      final groundMap = {for (var g in groundsData) g['id']: g['name']};
      final int courts = activeCourts > 0 ? activeCourts : 3;

      await _bookingsSubscription?.cancel();
      _bookingsSubscription = _bookingRepository
          .watchBookingsForGrounds(groundIds)
          .listen((bookings) {
        double todayRevenue = 0;
        int todayBookingsCount = 0;
        int pendingAcceptCount = 0;
        final List<dynamic> todaySlots = [];
        final List<dynamic> pendingApprovals = [];

        for (var b in bookings) {
          final status = b['status']?.toString().toLowerCase() ?? '';
          final bookingDateStr = b['booking_date'] ?? b['created_at'];

          if (bookingDateStr != null) {
            try {
              final bDate = DateTime.parse(bookingDateStr).toLocal();
              final now = DateTime.now();
              if (bDate.year == now.year &&
                  bDate.month == now.month &&
                  bDate.day == now.day) {
                todayBookingsCount++;
                if (status == 'confirmed' || status == 'completed') {
                  todayRevenue +=
                      (b['amount'] ?? b['total_amount'] ?? 0).toDouble();
                }
                todaySlots.add({
                  ...b,
                  'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
                });
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

        final occupancy = courts > 0
            ? '${(todayBookingsCount / (courts * 10) * 100).clamp(0, 100).toInt()}%'
            : '0%';

        emit(DashboardLoaded(
          ownerName: ownerName,
          venueName: venueName,
          activeCourts: courts,
          todayRevenue: '₹${todayRevenue.toInt()}',
          todayBookingsCount: todayBookingsCount,
          pendingAcceptCount: pendingAcceptCount,
          occupancyPercentage: occupancy,
          todaySlots: todaySlots,
          pendingApprovals: pendingApprovals,
        ));
      });
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
