import 'package:intl/intl.dart';

/// A single labeled value used to feed a bar/pie chart.
class RevenuePoint {
  final String label;
  final double amount;
  const RevenuePoint(this.label, this.amount);
}

const _countedStatuses = {'confirmed', 'completed'};

double _amountOf(Map<String, dynamic> booking) =>
    ((booking['amount'] ?? booking['total_amount'] ?? 0) as num).toDouble();

DateTime? _dateOf(Map<String, dynamic> booking) {
  final raw = booking['booking_date'] ?? booking['created_at'];
  if (raw == null) return null;
  try {
    return DateTime.parse(raw as String).toLocal();
  } catch (_) {
    return null;
  }
}

bool _countsTowardsRevenue(Map<String, dynamic> booking) {
  final status = booking['status']?.toString().toLowerCase() ?? '';
  return _countedStatuses.contains(status);
}

String _groundNameOf(Map<String, dynamic> booking) =>
    (booking['grounds'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown Ground';

String _sportOf(Map<String, dynamic> booking) {
  final raw = (booking['grounds'] as Map<String, dynamic>?)?['category'] as String?;
  if (raw == null || raw.isEmpty) return 'Other';
  return raw
      .split('_')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
}

String? _locationIdOf(Map<String, dynamic> booking) =>
    (booking['grounds'] as Map<String, dynamic>?)?['location_id'] as String?;

/// Filters bookings down to a single location (or returns everything when
/// [locationId] is null, meaning "All Locations").
List<Map<String, dynamic>> filterByLocation(
  List<Map<String, dynamic>> bookings,
  String? locationId,
) {
  if (locationId == null) return bookings;
  return bookings.where((b) => _locationIdOf(b) == locationId).toList();
}

double totalRevenue(List<Map<String, dynamic>> bookings) => bookings
    .where(_countsTowardsRevenue)
    .fold(0.0, (sum, b) => sum + _amountOf(b));

int totalBookingsCount(List<Map<String, dynamic>> bookings) =>
    bookings.where(_countsTowardsRevenue).length;

double averageBookingValue(List<Map<String, dynamic>> bookings) {
  final count = totalBookingsCount(bookings);
  return count == 0 ? 0 : totalRevenue(bookings) / count;
}

/// Daily revenue for the last 7 days (oldest first), labeled "d MMM".
List<RevenuePoint> weeklySeries(List<Map<String, dynamic>> bookings) {
  final today = DateTime.now();
  final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: 6 - i)));

  final totals = {for (final d in days) d: 0.0};
  for (final b in bookings) {
    if (!_countsTowardsRevenue(b)) continue;
    final date = _dateOf(b);
    if (date == null) continue;
    final key = DateTime(date.year, date.month, date.day);
    if (totals.containsKey(key)) {
      totals[key] = totals[key]! + _amountOf(b);
    }
  }

  return days
      .map((d) => RevenuePoint(DateFormat('d MMM').format(d), totals[d]!))
      .toList();
}

/// Monthly revenue for the last 6 months (oldest first), labeled "MMM".
List<RevenuePoint> monthlySeries(List<Map<String, dynamic>> bookings) {
  final now = DateTime.now();
  final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));

  final totals = {for (final m in months) m: 0.0};
  for (final b in bookings) {
    if (!_countsTowardsRevenue(b)) continue;
    final date = _dateOf(b);
    if (date == null) continue;
    final key = DateTime(date.year, date.month, 1);
    if (totals.containsKey(key)) {
      totals[key] = totals[key]! + _amountOf(b);
    }
  }

  return months
      .map((m) => RevenuePoint(DateFormat('MMM').format(m), totals[m]!))
      .toList();
}

/// Revenue grouped by ground, sorted highest first.
List<RevenuePoint> groundWiseRevenue(List<Map<String, dynamic>> bookings, {int limit = 8}) {
  final totals = <String, double>{};
  for (final b in bookings) {
    if (!_countsTowardsRevenue(b)) continue;
    final name = _groundNameOf(b);
    totals[name] = (totals[name] ?? 0) + _amountOf(b);
  }

  final points = totals.entries.map((e) => RevenuePoint(e.key, e.value)).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return points.take(limit).toList();
}

/// Revenue grouped by sport/category, sorted highest first.
List<RevenuePoint> sportWiseRevenue(List<Map<String, dynamic>> bookings) {
  final totals = <String, double>{};
  for (final b in bookings) {
    if (!_countsTowardsRevenue(b)) continue;
    final sport = _sportOf(b);
    totals[sport] = (totals[sport] ?? 0) + _amountOf(b);
  }

  final points = totals.entries.map((e) => RevenuePoint(e.key, e.value)).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return points;
}
