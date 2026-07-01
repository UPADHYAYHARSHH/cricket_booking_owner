enum BookingDateFilter { all, today, tomorrow, range }

abstract class BookingsState {}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

class BookingsLoaded extends BookingsState {
  final List<dynamic> allBookings;
  final List<dynamic> filteredBookings;
  final String searchQuery;
  final BookingDateFilter dateFilter;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  BookingsLoaded({
    required this.allBookings,
    required this.filteredBookings,
    this.searchQuery = '',
    this.dateFilter = BookingDateFilter.all,
    this.rangeStart,
    this.rangeEnd,
  });

  BookingsLoaded copyWith({
    List<dynamic>? allBookings,
    List<dynamic>? filteredBookings,
    String? searchQuery,
    BookingDateFilter? dateFilter,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    return BookingsLoaded(
      allBookings: allBookings ?? this.allBookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      searchQuery: searchQuery ?? this.searchQuery,
      dateFilter: dateFilter ?? this.dateFilter,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
    );
  }
}

class BookingsError extends BookingsState {
  final String message;
  BookingsError(this.message);
}
