import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
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

      final allGroundsData = await _bookingRepository.getOwnerGrounds(user.uid);
      final locationId = SharedPrefsService.instance.selectedLocationId;
      var groundsData = allGroundsData;
      if (locationId != null) {
        groundsData = groundsData.where((g) => g['location_id'] == locationId).toList();
      }
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
            final playerNameFromBooking = b['player_name']?.toString().isNotEmpty == true ? b['player_name'] : null;
            final playerNameFromUser = userData?['full_name'] ?? userData?['name'];
            print('[BookingsCubit] Booking $uidStr | Booking Name: $playerNameFromBooking | User Name: $playerNameFromUser');
            
            return <String, dynamic>{
              ...b,
              'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
              'player_name': playerNameFromBooking ?? playerNameFromUser ?? 'Customer',
              'player_image':
                  userData?['profile_image'] ?? userData?['avatar_url'],
              'member_since': userData?['created_at'],
              'past_bookings': pastBookingsCountMap[uidStr] ?? 0,
            };
          }).toList();

          // Re-apply whatever search/date filter the owner already had
          // selected, so a live update to the bookings list doesn't wipe it.
          final currentState = state;
          final query = currentState is BookingsLoaded ? currentState.searchQuery : '';
          final dateFilter = currentState is BookingsLoaded
              ? currentState.dateFilter
              : BookingDateFilter.all;
          final rangeStart = currentState is BookingsLoaded ? currentState.rangeStart : null;
          final rangeEnd = currentState is BookingsLoaded ? currentState.rangeEnd : null;

          emit(BookingsLoaded(
            allBookings: allBookings,
            filteredBookings:
                _applyFilters(allBookings, query, dateFilter, rangeStart, rangeEnd),
            searchQuery: query,
            dateFilter: dateFilter,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          ));
        } catch (_) {}
      });
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  void searchBookings(String query) {
    final currentState = state;
    if (currentState is! BookingsLoaded) return;
    emit(currentState.copyWith(
      searchQuery: query,
      filteredBookings: _applyFilters(
        currentState.allBookings,
        query,
        currentState.dateFilter,
        currentState.rangeStart,
        currentState.rangeEnd,
      ),
    ));
  }

  void setDateFilter(BookingDateFilter filter) {
    final currentState = state;
    if (currentState is! BookingsLoaded) return;
    final rangeStart = filter == BookingDateFilter.range ? currentState.rangeStart : null;
    final rangeEnd = filter == BookingDateFilter.range ? currentState.rangeEnd : null;
    emit(BookingsLoaded(
      allBookings: currentState.allBookings,
      filteredBookings: _applyFilters(
        currentState.allBookings,
        currentState.searchQuery,
        filter,
        rangeStart,
        rangeEnd,
      ),
      searchQuery: currentState.searchQuery,
      dateFilter: filter,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    ));
  }

  void setDateRange(DateTime start, DateTime end) {
    final currentState = state;
    if (currentState is! BookingsLoaded) return;
    emit(currentState.copyWith(
      dateFilter: BookingDateFilter.range,
      rangeStart: start,
      rangeEnd: end,
      filteredBookings: _applyFilters(
        currentState.allBookings,
        currentState.searchQuery,
        BookingDateFilter.range,
        start,
        end,
      ),
    ));
  }

  List<dynamic> _applyFilters(
    List<dynamic> bookings,
    String query,
    BookingDateFilter dateFilter,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  ) {
    var result = bookings;
    if (dateFilter != BookingDateFilter.all) {
      result =
          result.where((b) => _matchesDateFilter(b, dateFilter, rangeStart, rangeEnd)).toList();
    }
    if (query.isNotEmpty) {
      result = _applySearch(result, query);
    }
    return result;
  }

  bool _matchesDateFilter(
    dynamic booking,
    BookingDateFilter dateFilter,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  ) {
    final slotTimeStr = booking['slot_time']?.toString();
    if (slotTimeStr == null || slotTimeStr.isEmpty) return false;
    final slotTime = DateTime.tryParse(slotTimeStr)?.toLocal();
    if (slotTime == null) return false;

    final today = _dateOnly(DateTime.now());
    final slotDate = _dateOnly(slotTime);

    switch (dateFilter) {
      case BookingDateFilter.all:
        return true;
      case BookingDateFilter.today:
        return slotDate == today;
      case BookingDateFilter.tomorrow:
        return slotDate == today.add(const Duration(days: 1));
      case BookingDateFilter.range:
        if (rangeStart == null || rangeEnd == null) return true;
        final start = _dateOnly(rangeStart);
        final end = _dateOnly(rangeEnd);
        return !slotDate.isBefore(start) && !slotDate.isAfter(end);
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  List<dynamic> _applySearch(List<dynamic> bookings, String query) {
    final lowerQuery = query.toLowerCase();
    return bookings.where((b) {
      final playerName = (b['player_name'] ?? '').toString().toLowerCase();
      final groundName = (b['ground_name'] ?? '').toString().toLowerCase();
      final status = (b['status'] ?? '').toString().toLowerCase();
      final bookingId = (b['id'] ?? '').toString().toLowerCase();
      final displayId = _displayId(b).toLowerCase();
      return playerName.contains(lowerQuery) ||
          groundName.contains(lowerQuery) ||
          status.contains(lowerQuery) ||
          bookingId.contains(lowerQuery) ||
          displayId.contains(lowerQuery);
    }).toList();
  }

  /// Matches the "CB..." id shown to the owner on the booking cards/details
  /// screen, since that's what an owner would actually type into search.
  String _displayId(dynamic booking) {
    final raw = booking['display_id']?.toString();
    if (raw != null && raw.isNotEmpty && raw != '0') return 'cb$raw';
    final fullId = booking['id']?.toString() ?? '';
    return 'cb${fullId.length > 5 ? fullId.substring(0, 5) : fullId}';
  }
}
