import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro_owner/owner_booking/domain/models/virtual_slot.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/slot_repository.dart';
import 'slot_state.dart';

class SlotCubit extends Cubit<SlotState> {
  final SlotRepository _slotRepository;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

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

      final groundsData = await _slotRepository.getOwnerGrounds(user.uid);
      if (groundsData.isEmpty) {
        emit(SlotLoaded(
          venueName: venueName,
          grounds: [],
          selectedGroundId: '',
          selectedDate: DateTime.now(),
          slots: [],
          bookedCount: 0,
          totalSlots: 0,
          todayRevenue: 0,
        ));
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
      final slotDurationMins = ground['slot_duration'] ?? 60;
      final int defaultPrice = (ground['price_per_hour'] as num?)?.toInt() ?? 800;

      final openParts = openingTimeStr.split(':');
      final closeParts = closingTimeStr.split(':');
      DateTime startTime = DateTime(date.year, date.month, date.day,
          int.parse(openParts[0]), int.parse(openParts[1]));
      DateTime endTime = DateTime(date.year, date.month, date.day,
          int.parse(closeParts[0]), int.parse(closeParts[1]));

      if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      final dateStartStr =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final dateEndStr =
          DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

      await _bookingsSubscription?.cancel();
      _bookingsSubscription = _slotRepository
          .watchBookingsForGround(groundId)
          .listen((allBookingsData) {
        final bookingsData = allBookingsData.where((b) {
          if (b['status'] != 'confirmed') return false;
          final slotTime = b['slot_time'];
          if (slotTime == null) return false;
          return slotTime.compareTo(dateStartStr) >= 0 &&
              slotTime.compareTo(dateEndStr) <= 0;
        }).toList();

        List<VirtualSlot> virtualSlots = [];
        DateTime currentSlotTime = startTime;

        while (currentSlotTime.isBefore(endTime)) {
          final nextSlotTime =
              currentSlotTime.add(Duration(minutes: slotDurationMins));
          if (nextSlotTime.isAfter(endTime)) break;

          final isPeak =
              currentSlotTime.hour >= 18 && currentSlotTime.hour <= 21;
          virtualSlots.add(VirtualSlot(
            startTime: currentSlotTime,
            endTime: nextSlotTime,
            status: SlotStatus.open,
            price: isPeak ? defaultPrice + 100 : defaultPrice,
          ));
          currentSlotTime = nextSlotTime;
        }

        int todayRevenue = 0;
        for (var b in bookingsData) {
          todayRevenue += (b['amount'] as num?)?.toInt() ?? defaultPrice;
        }

        for (int i = 0; i < virtualSlots.length; i++) {
          final vSlot = virtualSlots[i];
          final matchingBooking =
              bookingsData.cast<Map<String, dynamic>?>().firstWhere(
            (b) {
              if (b == null) return false;
              final bookingTime =
                  DateTime.parse(b['slot_time']).toLocal();
              return bookingTime.hour == vSlot.startTime.hour &&
                  bookingTime.minute == vSlot.startTime.minute;
            },
            orElse: () => null,
          );

          if (matchingBooking != null) {
            virtualSlots[i] = VirtualSlot(
              startTime: vSlot.startTime,
              endTime: vSlot.endTime,
              status: SlotStatus.booked,
              price: (matchingBooking['amount'] as num?)?.toInt() ?? vSlot.price,
              bookedPlayerName:
                  'Customer (ID: ${matchingBooking['user_id'].toString().substring(0, 4)})',
              bookedPlayersCount: 8,
              bookingId: matchingBooking['id'],
            );
          } else if (vSlot.startTime.hour == 12) {
            virtualSlots[i] = VirtualSlot(
              startTime: vSlot.startTime,
              endTime: vSlot.endTime,
              status: SlotStatus.maintenance,
              price: vSlot.price,
            );
          } else if (vSlot.startTime.hour >= 18 && vSlot.startTime.hour <= 21) {
            virtualSlots[i] = VirtualSlot(
              startTime: vSlot.startTime,
              endTime: vSlot.endTime,
              status: SlotStatus.peak,
              price: vSlot.price,
            );
          }
        }

        emit(SlotLoaded(
          venueName: venueName,
          grounds: grounds,
          selectedGroundId: groundId,
          selectedDate: date,
          slots: virtualSlots,
          bookedCount: bookingsData.length,
          totalSlots: virtualSlots.length,
          todayRevenue: todayRevenue,
        ));
      });
    } catch (e) {
      emit(SlotError(e.toString()));
    }
  }
}
