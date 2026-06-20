import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  final BookingRepository _bookingRepository;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  BookingsCubit(this._bookingRepository) : super(BookingsInitial());

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchBookings() async {
    emit(BookingsLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(BookingsError('User not logged in'));
        return;
      }

      final groundsData = await _bookingRepository.getOwnerGrounds(user.uid);
      if (groundsData.isEmpty) {
        emit(BookingsLoaded(allBookings: [], filteredBookings: []));
        return;
      }

      final groundIds = groundsData.map((g) => g['id'] as Object).toList();
      final groundMap = {for (var g in groundsData) g['id']: g['name']};

      await _bookingsSubscription?.cancel();
      _bookingsSubscription = _bookingRepository
          .watchBookingsForGrounds(groundIds)
          .listen((bookings) async {
        try {
          final userIds = bookings
              .map((b) => b['user_id'])
              .where((id) => id != null)
              .cast<String>()
              .toSet()
              .toList();

          final users = await _bookingRepository.fetchUsers(userIds);
          final userPastBookings =
              await _bookingRepository.fetchUserPastBookings(userIds);

          final userMap = {for (var u in users) u['id']: u};
          final pastBookingsCountMap = <String, int>{};
          for (var ub in userPastBookings) {
            final uid = ub['user_id'].toString();
            pastBookingsCountMap[uid] = (pastBookingsCountMap[uid] ?? 0) + 1;
          }

          final allBookings = bookings.map((b) {
            final userData = userMap[b['user_id']];
            final uidStr = b['user_id']?.toString() ?? '';
            return <String, dynamic>{
              ...b,
              'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
              'player_name': userData?['full_name'] ??
                  userData?['name'] ??
                  'Customer (ID: ${uidStr.length > 4 ? uidStr.substring(0, 4) : uidStr})',
              'player_image':
                  userData?['profile_image'] ?? userData?['avatar_url'],
              'member_since': userData?['created_at'],
              'past_bookings': pastBookingsCountMap[uidStr] ?? 0,
            };
          }).toList();

          final currentState = state;
          final currentQuery =
              currentState is BookingsLoaded ? currentState.searchQuery : '';

          final filtered = _applyFilter(allBookings, currentQuery);
          emit(BookingsLoaded(
            allBookings: allBookings,
            filteredBookings: filtered,
            searchQuery: currentQuery,
          ));
        } catch (_) {}
      });
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  void searchBookings(String query) {
    final currentState = state;
    if (currentState is BookingsLoaded) {
      final filtered = query.isEmpty
          ? currentState.allBookings
          : _applyFilter(currentState.allBookings, query);
      emit(currentState.copyWith(filteredBookings: filtered, searchQuery: query));
    }
  }

  List<dynamic> _applyFilter(List<dynamic> bookings, String query) {
    if (query.isEmpty) return bookings;
    final lowerQuery = query.toLowerCase();
    return bookings.where((b) {
      final playerName = (b['player_name'] ?? '').toString().toLowerCase();
      final bookingId = (b['id'] ?? '').toString().toLowerCase();
      final status = (b['status'] ?? '').toString().toLowerCase();
      return playerName.contains(lowerQuery) ||
          bookingId.contains(lowerQuery) ||
          status.contains(lowerQuery);
    }).toList();
  }
}
