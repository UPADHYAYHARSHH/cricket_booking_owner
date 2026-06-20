abstract class BookingsState {}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

class BookingsLoaded extends BookingsState {
  final List<dynamic> allBookings;
  final List<dynamic> filteredBookings;
  final String searchQuery;

  BookingsLoaded({
    required this.allBookings,
    required this.filteredBookings,
    this.searchQuery = '',
  });

  BookingsLoaded copyWith({
    List<dynamic>? allBookings,
    List<dynamic>? filteredBookings,
    String? searchQuery,
  }) {
    return BookingsLoaded(
      allBookings: allBookings ?? this.allBookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BookingsError extends BookingsState {
  final String message;
  BookingsError(this.message);
}
