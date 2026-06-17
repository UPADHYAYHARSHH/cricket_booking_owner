import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
import 'package:turfpro_owner/blocs/slot/slot_state.dart';

class SlotCubit extends Cubit<SlotState> {
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  SlotCubit() : super(SlotInitial());

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchInitialData() async {
    emit(SlotLoading());
    try {
      final user = f_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(SlotError("User not logged in"));
        return;
      }

      // Fetch owner details for venue name
      final ownerRes = await Supabase.instance.client
          .from('owner_details')
          .select('venue_name')
          .eq('id', user.uid)
          .maybeSingle();
      
      final venueName = ownerRes?['venue_name'] ?? 'Your Venue';

      // Fetch grounds owned by this owner
      final groundsData = await Supabase.instance.client
          .from('grounds')
          .select()
          .eq('owner_id', user.uid)
          .order('created_at', ascending: true);

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
      
      // Parse operating hours
      final openingTimeStr = ground['opening_time'] ?? '06:00:00';
      final closingTimeStr = ground['closing_time'] ?? '23:00:00';
      final slotDurationMins = ground['slot_duration'] ?? 60;
      final int defaultPrice = (ground['price_per_hour'] as num?)?.toInt() ?? 800;

      final openParts = openingTimeStr.split(':');
      final closeParts = closingTimeStr.split(':');

      DateTime startTime = DateTime(date.year, date.month, date.day, int.parse(openParts[0]), int.parse(openParts[1]));
      DateTime endTime = DateTime(date.year, date.month, date.day, int.parse(closeParts[0]), int.parse(closeParts[1]));

      if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      // Cancel any existing subscription
      await _bookingsSubscription?.cancel();

      final dateStartStr = DateTime(date.year, date.month, date.day).toIso8601String();
      final dateEndStr = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

      // Subscribe to real-time bookings for this ground and date
      _bookingsSubscription = Supabase.instance.client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('ground_id', groundId)
          .listen((allBookingsData) {

            // Filter for the selected date on the client side
            final bookingsData = allBookingsData.where((b) {
              if (b['status'] != 'confirmed') return false;
              final slotTime = b['slot_time'];
              if (slotTime == null) return false;
              return slotTime.compareTo(dateStartStr) >= 0 && slotTime.compareTo(dateEndStr) <= 0;
            }).toList();

            // Generate base virtual slots
            List<VirtualSlot> virtualSlots = [];
            DateTime currentSlotTime = startTime;
            
            while (currentSlotTime.isBefore(endTime)) {
              final nextSlotTime = currentSlotTime.add(Duration(minutes: slotDurationMins));
              if (nextSlotTime.isAfter(endTime)) break;
              
              final isPeak = currentSlotTime.hour >= 18 && currentSlotTime.hour <= 21;
              final slotPrice = isPeak ? defaultPrice + 100 : defaultPrice;

              virtualSlots.add(VirtualSlot(
                startTime: currentSlotTime,
                endTime: nextSlotTime,
                status: SlotStatus.open,
                price: slotPrice,
              ));
              
              currentSlotTime = nextSlotTime;
            }

            int todayRevenue = 0;
            for (var b in bookingsData) {
              todayRevenue += (b['amount'] as num?)?.toInt() ?? (defaultPrice as num).toInt();
            }
            int bookedCount = bookingsData.length;

            // Merge bookings onto slots
            for (int i = 0; i < virtualSlots.length; i++) {
              final vSlot = virtualSlots[i];
              
              // Find if any booking matches this start time
              final matchingBooking = bookingsData.cast<Map<String, dynamic>?>().firstWhere(
                (b) {
                  if (b == null) return false;
                  final bookingTime = DateTime.parse(b['slot_time']).toLocal();
                  return bookingTime.hour == vSlot.startTime.hour && bookingTime.minute == vSlot.startTime.minute;
                }, 
                orElse: () => null,
              );

              if (matchingBooking != null) {
                virtualSlots[i] = VirtualSlot(
                  startTime: vSlot.startTime,
                  endTime: vSlot.endTime,
                  status: SlotStatus.booked,
                  price: (matchingBooking['amount'] as num?)?.toInt() ?? vSlot.price,
                  bookedPlayerName: 'Customer (ID: ${matchingBooking['user_id'].toString().substring(0, 4)})',
                  bookedPlayersCount: 8, // mock players count
                  bookingId: matchingBooking['id'],
                );
              } else {
                // Mock maintenance at 12 PM for demo purposes if nothing is booked
                if (vSlot.startTime.hour == 12) {
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
            }

            emit(SlotLoaded(
              venueName: venueName,
              grounds: grounds,
              selectedGroundId: groundId,
              selectedDate: date,
              slots: virtualSlots,
              bookedCount: bookedCount,
              totalSlots: virtualSlots.length,
              todayRevenue: todayRevenue,
            ));
      });

    } catch (e) {
      emit(SlotError(e.toString()));
    }
  }
}
