import 'dart:convert';

class BookingFinancialUtil {
  /// Resolves the owner's net earnings for a booking.
  /// Prioritizes the database `owner_earnings` column,
  /// then `notes['owner_earnings']`, `notes['slot_price']`, `base_amount`,
  /// and finally gross amount.
  static double getOwnerEarnings(Map<dynamic, dynamic>? booking) {
    if (booking == null) return 0.0;

    if (booking['owner_earnings'] != null) {
      return (booking['owner_earnings'] as num).toDouble();
    }

    Map<String, dynamic>? parsedNotes;
    final notes = booking['notes'];
    if (notes != null) {
      if (notes is Map<String, dynamic>) {
        parsedNotes = notes;
      } else if (notes is Map) {
        parsedNotes = Map<String, dynamic>.from(notes);
      } else if (notes is String) {
        final str = notes.trim();
        if (str.startsWith('{') && str.endsWith('}')) {
          try {
            parsedNotes = jsonDecode(str) as Map<String, dynamic>?;
          } catch (_) {}
        }
      }
    }

    if (parsedNotes?['owner_earnings'] != null) {
      return (parsedNotes!['owner_earnings'] as num).toDouble();
    }
    if (parsedNotes?['slot_price'] != null) {
      return (parsedNotes!['slot_price'] as num).toDouble();
    }
    if (booking['base_amount'] != null) {
      return (booking['base_amount'] as num).toDouble();
    }

    final gross = booking['amount'] ?? booking['total_amount'] ?? 0;
    return (gross as num).toDouble();
  }

  /// Formats the earnings into a display string without unnecessary trailing decimals, e.g. "1200" or "1200.50".
  static String formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}
