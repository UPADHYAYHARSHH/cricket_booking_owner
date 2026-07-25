import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/owner_booking/domain/models/virtual_slot.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/slot_repository.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
import 'slot_state.dart';

class SlotCubit extends Cubit<SlotState> {
  final SlotRepository _slotRepository;

  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  // Cached state for stream rebuilds and optimistic updates
  List<Map<String, dynamic>> _latestBookings = [];
  String _venueName = '';
  List<Map<String, dynamic>> _grounds = [];
  String _selectedGroundId = '';
  DateTime _selectedDate = DateTime.now();
  DateTime _slotStart = DateTime.now();
  DateTime _slotEnd = DateTime.now();
  int _defaultPrice = 800;
  int _weekendPrice = 800;
  int _slotDurationMins = 60;

  SlotCubit(this._slotRepository) : super(SlotInitial());

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchInitialData() async {
    emit(SlotLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(SlotError('User not logged in'));
        return;
      }

      final ownerRes = await _slotRepository.getOwnerDetails(user.uid);
      final venueName = ownerRes?['venue_name'] ?? 'Your Venue';

      final allGroundsData = await _slotRepository.getOwnerGrounds(user.uid);
      final locationId = SharedPrefsService.instance.selectedLocationId;
      var groundsData = allGroundsData;
      if (locationId != null) {
        groundsData = groundsData
            .where((g) => g['location_id'] == locationId)
            .toList();
      }
      if (groundsData.isEmpty) {
        emit(
          SlotLoaded(
            venueName: venueName,
            grounds: [],
            selectedGroundId: '',
            selectedDate: DateTime.now(),
            slots: [],
            bookedCount: 0,
            totalSlots: 0,
            todayRevenue: 0,
            blockedCount: 0,
          ),
        );
        return;
      }

      final firstGroundId = groundsData.first['id'] as String;
      await fetchSlotsForDate(
        groundId: firstGroundId,
        date: DateTime.now(),
        venueName: venueName,
        grounds: groundsData,
      );
    } catch (e) {
      emit(SlotError(e.toString()));
    }
  }

  Future<void> selectDate(DateTime date) async {
    if (state is SlotLoaded) {
      final currentState = state as SlotLoaded;
      emit(SlotLoading());
      await fetchSlotsForDate(
        groundId: currentState.selectedGroundId,
        date: date,
        venueName: currentState.venueName,
        grounds: currentState.grounds,
      );
    }
  }

  Future<void> selectGround(String groundId) async {
    if (state is SlotLoaded) {
      final currentState = state as SlotLoaded;
      emit(SlotLoading());
      await fetchSlotsForDate(
        groundId: groundId,
        date: currentState.selectedDate,
        venueName: currentState.venueName,
        grounds: currentState.grounds,
      );
    }
  }

  Future<void> fetchSlotsForDate({
    required String groundId,
    required DateTime date,
    required String venueName,
    required List<Map<String, dynamic>> grounds,
  }) async {
    try {
      final ground = grounds.firstWhere((g) => g['id'] == groundId);
      final openingTimeStr = ground['opening_time'] ?? '06:00:00';
      final closingTimeStr = ground['closing_time'] ?? '23:00:00';
      final slotDurationMins = _parseSlotDuration(ground['slot_duration']);
      final int defaultPrice =
          (ground['price_per_hour'] as num?)?.toInt() ?? 800;
      final int weekendPrice =
          (ground['weekend_price'] as num?)?.toInt() ?? defaultPrice;

      final openParts = openingTimeStr.split(':');
      final closeParts = closingTimeStr.split(':');
      final slotStart = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(openParts[0]),
        int.parse(openParts[1]),
      );
      var slotEnd = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(closeParts[0]),
        int.parse(closeParts[1]),
      );

      if (slotEnd.isBefore(slotStart) || slotEnd.isAtSameMomentAs(slotStart)) {
        slotEnd = slotEnd.add(const Duration(days: 1));
      }

      _venueName = venueName;
      _grounds = grounds;
      _selectedGroundId = groundId;
      _selectedDate = date;
      _slotStart = slotStart;
      _slotEnd = slotEnd;
      _defaultPrice = defaultPrice;
      _weekendPrice = weekendPrice;
      _slotDurationMins = slotDurationMins;
      _latestBookings = [];

      await _bookingsSubscription?.cancel();

      // Watch bookings table for real-time sync
      _bookingsSubscription = _slotRepository
          .watchBookingsForGround(groundId)
          .listen((data) {
            _latestBookings = data;
            _rebuildSlots();
          });
    } catch (e) {
      emit(SlotError(e.toString()));
    }
  }

  int _parseSlotDuration(dynamic raw) {
    try {
      if (raw == null) return 60;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final s = raw.trim().toLowerCase();
        final numStr = RegExp(r'[0-9]+(?:\.[0-9]+)?').firstMatch(s)?.group(0);
        if (numStr == null) return 60;
        final value = double.tryParse(numStr) ?? 0.0;
        if (s.contains('hour')) {
          return (value * 60).round();
        }
        // assume minutes if 'min' present or no unit
        return value.round();
      }
    } catch (e) {
      // fallback
    }
    return 60;
  }

  void _rebuildSlots() {
    final dateStartStr = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).toIso8601String();
    final dateEndStr = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    ).toIso8601String();

    final bookingsForDate = _latestBookings.where((b) {
      if (b['status'] != 'confirmed' && b['status'] != 'paid') return false;
      final slotTime = b['slot_time'];
      if (slotTime == null) return false;
      return slotTime.compareTo(dateStartStr) >= 0 &&
          slotTime.compareTo(dateEndStr) <= 0;
    }).toList();

    // Determine price based on weekday/weekend
    final isWeekend =
        _selectedDate.weekday == DateTime.saturday ||
        _selectedDate.weekday == DateTime.sunday;
    final basePrice = isWeekend ? _weekendPrice : _defaultPrice;

    final List<VirtualSlot> virtualSlots = [];
    DateTime currentSlotTime = _slotStart;

    while (currentSlotTime.isBefore(_slotEnd)) {
      final nextSlotTime = currentSlotTime.add(
        Duration(minutes: _slotDurationMins),
      );
      if (nextSlotTime.isAfter(_slotEnd)) break;

      final isPeak = currentSlotTime.hour >= 18 && currentSlotTime.hour <= 21;
      virtualSlots.add(
        VirtualSlot(
          startTime: currentSlotTime,
          endTime: nextSlotTime,
          status: isPeak ? SlotStatus.peak : SlotStatus.open,
          price: isPeak ? basePrice + 100 : basePrice,
        ),
      );
      currentSlotTime = nextSlotTime;
    }

    int todayRevenue = 0;
    for (var b in bookingsForDate) {
      if (b['user_id'] != null) {
        todayRevenue += (b['amount'] as num?)?.toInt() ?? _defaultPrice;
      }
    }

    for (int i = 0; i < virtualSlots.length; i++) {
      final vSlot = virtualSlots[i];

      final matchingBooking = bookingsForDate
          .cast<Map<String, dynamic>?>()
          .firstWhere((b) {
            if (b == null) return false;
            final bookingTime = DateTime.parse(b['slot_time']).toLocal();
            return bookingTime.hour == vSlot.startTime.hour &&
                bookingTime.minute == vSlot.startTime.minute;
          }, orElse: () => null);

      if (matchingBooking != null) {
        final isOwner = matchingBooking['user_id'] == null;

        if (isOwner) {
          virtualSlots[i] = VirtualSlot(
            startTime: vSlot.startTime,
            endTime: vSlot.endTime,
            status: SlotStatus.blocked,
            price: vSlot.price,
            blockedSlotId: matchingBooking['id']?.toString(),
            blockReason: matchingBooking['notes']?.toString(),
            bookingDetails: matchingBooking,
          );
        } else {
          virtualSlots[i] = VirtualSlot(
            startTime: vSlot.startTime,
            endTime: vSlot.endTime,
            status: SlotStatus.booked,
            price: (matchingBooking['amount'] as num?)?.toInt() ?? vSlot.price,
            bookedPlayerName:
                matchingBooking['player_name']?.toString().isNotEmpty == true
                ? matchingBooking['player_name']
                : 'Customer (ID: ${matchingBooking['user_id']?.toString().substring(0, 4) ?? '—'})',
            bookedPlayersCount: 8,
            bookingId: matchingBooking['id'],
            bookingDetails: matchingBooking,
          );
        }
      }
    }

    emit(
      SlotLoaded(
        venueName: _venueName,
        grounds: _grounds,
        selectedGroundId: _selectedGroundId,
        selectedDate: _selectedDate,
        slots: virtualSlots,
        bookedCount: bookingsForDate.where((b) => b['user_id'] != null).length,
        blockedCount: bookingsForDate.where((b) => b['user_id'] == null).length,
        totalSlots: virtualSlots.length,
        todayRevenue: todayRevenue,
      ),
    );
  }

  /// Books a slot as the owner. Uses optimistic update for instant UI feedback.
  Future<void> bookOwnerSlot(
    DateTime startTime,
    int price, {
    String? note,
  }) async {
    try {
      final localSlotTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        startTime.hour,
        startTime.minute,
      );
      final slotTimeIso = localSlotTime.toUtc().toIso8601String();
      final endTime = localSlotTime.add(Duration(minutes: _slotDurationMins));
      final period = _periodForSlot(localSlotTime, endTime);
      final sportName = _sportNameForGround(_selectedGroundId);

      // Optimistic update — null user_id marks an owner booking
      final placeholder = {
        'id': '_pending_${startTime.millisecondsSinceEpoch}',
        'ground_id': _selectedGroundId,
        'slot_time': slotTimeIso,
        'amount': price,
        'status': 'confirmed',
        'user_id': null,
        'sport_name': sportName,
        'period': period,
        'checked_in': false,
        'notes': ?note,
      };
      _latestBookings = [..._latestBookings, placeholder];
      _rebuildSlots();

      // Persist and swap placeholder with real DB row
      final inserted = await _slotRepository.insertOwnerBooking(
        groundId: _selectedGroundId,
        slotTime: slotTimeIso,
        price: price,
        sportName: sportName,
        period: period,
        note: note,
      );
      _latestBookings =
          _latestBookings.where((b) => b['id'] != placeholder['id']).toList()
            ..add(inserted);
      _rebuildSlots();
    } catch (e) {
      _latestBookings = _latestBookings
          .where((b) => b['id']?.toString().startsWith('_pending_') != true)
          .toList();
      _rebuildSlots();
      emit(SlotError('Failed to book slot: $e'));
    }
  }

  String _periodForSlot(DateTime startTime, DateTime endTime) {
    final fmt = DateFormat('h:mm a');
    return '${fmt.format(startTime)} - ${fmt.format(endTime)}';
  }

  String _sportNameForGround(String groundId) {
    final ground = _grounds.cast<Map<String, dynamic>?>().firstWhere(
      (g) => g?['id'] == groundId,
      orElse: () => null,
    );
    // Prefer category, fall back to ground_type, then ground name
    final raw =
        (ground?['category']?.toString().trim().isNotEmpty == true
                ? ground!['category']
                : ground?['ground_type']?.toString().trim().isNotEmpty == true
                ? ground!['ground_type']
                : ground?['name'])
            ?.toString()
            .trim() ??
        '';
    if (raw.isEmpty) return 'Sport';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  /// Removes an owner-booked slot. Optimistic — removes from UI before server confirms.
  Future<void> unbookOwnerSlot(String bookingId) async {
    final removed = _latestBookings.firstWhere(
      (b) => b['id'] == bookingId,
      orElse: () => {},
    );
    try {
      _latestBookings = _latestBookings
          .where((b) => b['id'] != bookingId)
          .toList();
      _rebuildSlots();
      await _slotRepository.deleteOwnerBooking(bookingId);
    } catch (e) {
      // Rollback
      if (removed.isNotEmpty) {
        _latestBookings = [..._latestBookings, removed];
        _rebuildSlots();
      }
      emit(SlotError('Failed to unbook slot: $e'));
    }
  }
}
