import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  BookingsCubit() : super(BookingsInitial());

  Future<void> fetchBookings() async {
    emit(BookingsLoading());
    try {
      final user = f_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(BookingsError("User not logged in"));
        return;
      }

      // Fetch grounds owned by this owner
      final groundsData = await Supabase.instance.client
          .from('grounds')
          .select('id, name')
          .eq('owner_id', user.uid);

      if (groundsData.isEmpty) {
        emit(BookingsLoaded(allBookings: [], filteredBookings: []));
        return;
      }

      final groundIds = groundsData.map((g) => g['id']).toList();
      final groundMap = {for (var g in groundsData) g['id']: g['name']};

      // Fetch all bookings for those grounds
      final bookings = await Supabase.instance.client
          .from('bookings')
          .select()
          .filter('ground_id', 'in', groundIds)
          .order('created_at', ascending: false);

      List<dynamic> allBookings = [];
      for (var b in bookings) {
        allBookings.add({
          ...b,
          'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
          // Assuming user names are fetched or joined, mock for now since we don't have user profiles joined
          'player_name': 'Customer (ID: ${b['user_id'].toString().substring(0, 4)})',
        });
      }

      emit(BookingsLoaded(allBookings: allBookings, filteredBookings: allBookings));
    } catch (e) {
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
