import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  BookingsCubit() : super(BookingsInitial());

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchBookings() async {
    emit(BookingsLoading());
    try {
      final user = f_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("BookingsCubit: User is null");
        emit(BookingsError("User not logged in"));
        return;
      }
      
      print("BookingsCubit: Fetching grounds for owner UID: ${user.uid}");

      // Fetch grounds owned by this owner
      final groundsData = await Supabase.instance.client
          .from('grounds')
          .select('id, name')
          .eq('owner_id', user.uid);

      print("BookingsCubit: Grounds returned from DB: ${groundsData.length}");

      if (groundsData.isEmpty) {
        print("BookingsCubit: No grounds found for this owner.");
        emit(BookingsLoaded(allBookings: [], filteredBookings: []));
        return;
      }

      final List<Object> groundIds = groundsData.map((g) => g['id'] as Object).toList();
      final groundMap = {for (var g in groundsData) g['id']: g['name']};
      
      print("BookingsCubit: Ground IDs list: $groundIds");

      // Cancel existing subscription if any
      await _bookingsSubscription?.cancel();

      // Subscribe to all bookings for those grounds
      _bookingsSubscription = Supabase.instance.client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .inFilter('ground_id', groundIds)
          .order('created_at', ascending: false)
          .listen((bookings) async {
            try {
              List<dynamic> users = [];
              final userIds = bookings.map((b) => b['user_id']).where((id) => id != null).toSet().toList();
              
              if (userIds.isNotEmpty) {
                try {
                  users = await Supabase.instance.client
                      .from('users')
                      .select()
                      .filter('id', 'in', userIds);
                } catch (e) {
                  print("BookingsCubit: Error fetching users: $e");
                }
              }
              
              final userMap = {for (var u in users) u['id']: u};
              
              List<dynamic> userBookings = [];
              if (userIds.isNotEmpty) {
                try {
                  userBookings = await Supabase.instance.client
                      .from('bookings')
                      .select('user_id')
                      .filter('user_id', 'in', userIds);
                } catch (e) {
                  print("BookingsCubit: Error fetching user past bookings: $e");
                }
              }
              
              final pastBookingsCountMap = <String, int>{};
              for (var ub in userBookings) {
                final uid = ub['user_id'].toString();
                pastBookingsCountMap[uid] = (pastBookingsCountMap[uid] ?? 0) + 1;
              }

              List<dynamic> allBookings = [];
              for (var b in bookings) {
                final userData = userMap[b['user_id']];
                final uidStr = b['user_id']?.toString() ?? '';
                allBookings.add({
                  ...b,
                  'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
                  'player_name': userData?['full_name'] ?? userData?['name'] ?? 'Customer (ID: ${uidStr.length > 4 ? uidStr.substring(0, 4) : uidStr})',
                  'player_image': userData?['profile_image'] ?? userData?['avatar_url'],
                  'member_since': userData?['created_at'],
                  'past_bookings': pastBookingsCountMap[uidStr] ?? 0,
                });
              }

              final currentState = state;
              String currentQuery = '';
              if (currentState is BookingsLoaded) {
                currentQuery = currentState.searchQuery;
              }

              List<dynamic> filtered = allBookings;
              if (currentQuery.isNotEmpty) {
                final lowerQuery = currentQuery.toLowerCase();
                filtered = allBookings.where((b) {
                  final playerName = (b['player_name'] ?? '').toString().toLowerCase();
                  final bookingId = (b['id'] ?? '').toString().toLowerCase();
                  final status = (b['status'] ?? '').toString().toLowerCase();
                  return playerName.contains(lowerQuery) || bookingId.contains(lowerQuery) || status.contains(lowerQuery);
                }).toList();
              }

              emit(BookingsLoaded(allBookings: allBookings, filteredBookings: filtered, searchQuery: currentQuery));
            } catch (innerE) {
              print("BookingsCubit: Error in stream listener: $innerE");
            }
          });

    } catch (e) {
      print("BookingsCubit: Error caught: $e");
      emit(BookingsError(e.toString()));
    }
  }

  void searchBookings(String query) {
    final currentState = state;
    if (currentState is BookingsLoaded) {
      if (query.isEmpty) {
        emit(currentState.copyWith(filteredBookings: currentState.allBookings, searchQuery: query));
      } else {
        final lowerQuery = query.toLowerCase();
        final filtered = currentState.allBookings.where((b) {
          final playerName = (b['player_name'] ?? '').toString().toLowerCase();
          final bookingId = (b['id'] ?? '').toString().toLowerCase();
          final status = (b['status'] ?? '').toString().toLowerCase();
          
          return playerName.contains(lowerQuery) || bookingId.contains(lowerQuery) || status.contains(lowerQuery);
        }).toList();
        
        emit(currentState.copyWith(filteredBookings: filtered, searchQuery: query));
      }
    }
  }
}
