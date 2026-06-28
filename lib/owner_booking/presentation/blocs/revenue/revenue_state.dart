abstract class RevenueState {}

class RevenueInitial extends RevenueState {}

class RevenueLoading extends RevenueState {}

class RevenueLoaded extends RevenueState {
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> locations;

  RevenueLoaded({required this.bookings, required this.locations});
}

class RevenueError extends RevenueState {
  final String message;
  RevenueError(this.message);
}
