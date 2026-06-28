abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final String ownerName;
  final String venueName;
  final int activeCourts;
  final String todayRevenue;
  final String revenueChangeLabel;
  final int todayBookingsCount;
  final int pendingAcceptCount;
  final String occupancyPercentage;
  final List<dynamic> todaySlots;
  final List<dynamic> pendingApprovals;
  final List<Map<String, dynamic>> locations;
  final String? selectedLocationId;

  DashboardLoaded({
    required this.ownerName,
    required this.venueName,
    required this.activeCourts,
    required this.todayRevenue,
    this.revenueChangeLabel = '—',
    required this.todayBookingsCount,
    required this.pendingAcceptCount,
    required this.occupancyPercentage,
    this.todaySlots = const [],
    this.pendingApprovals = const [],
    this.locations = const [],
    this.selectedLocationId,
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
