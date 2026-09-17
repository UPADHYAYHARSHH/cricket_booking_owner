import 'dart:convert';
import 'package:turfpro_owner/common/services/app_config_service.dart';

class BookingFinancialUtil {
  /// Resolves the owner's net earnings for a booking.
  /// Prioritizes the database `owner_earnings` column,
  /// then `notes['owner_earnings']`, `notes['slot_price']`, `base_amount`,
  /// and finally gross amount.
  static double getOwnerEarnings(Map<dynamic, dynamic>? booking) {
    if (booking == null) return 0.0;

    Map<String, dynamic>? parsedNotes;
    final notes = booking['notes'];
    if (notes != null) {
      if (notes is Map<String, dynamic>) {
        parsedNotes = notes;
      } else if (notes is Map) {
        parsedNotes = Map<String, dynamic>.from(notes);
      } else if (notes is String) {
        final str = notes.trim();
        if (str.isNotEmpty) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is Map) {
              parsedNotes = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {}
        }
      }
    }

    final gross =
        ((booking['amount'] ?? booking['total_amount'] ?? parsedNotes?['grand_total'] ?? 0) as num)
            .toDouble();

    final slotPrice = (parsedNotes?['slot_price'] as num?)?.toDouble() ??
        (booking['base_amount'] as num?)?.toDouble();

    final double pFee = (parsedNotes?['platform_fee'] as num?)?.toDouble() ??
        (booking['platform_fee'] as num?)?.toDouble() ??
        0.0;

    final double gstAmount = (parsedNotes?['gst_amount'] as num?)?.toDouble() ??
        (booking['gst_amount'] as num?)?.toDouble() ??
        0.0;

    final bool isPlatformFeeFree = parsedNotes?['is_platform_fee_free'] == true ||
        parsedNotes?['platform_fee_is_free'] == true ||
        booking['is_platform_fee_free'] == true ||
        (slotPrice != null && pFee > 0 && (slotPrice + gstAmount >= gross));

    final double base = slotPrice != null && slotPrice > 0
        ? slotPrice
        : (isPlatformFeeFree
            ? (gross - gstAmount).clamp(0.0, gross)
            : (gross - pFee - gstAmount).clamp(0.0, gross));

    final double storedComm = (booking['commission_rate'] as num?)?.toDouble() ??
        (parsedNotes?['commission_rate'] as num?)?.toDouble() ??
        0.0;
    final cRate = storedComm > 0 ? storedComm : AppConfigService.instance.commissionRate;
    final cIsPct = booking['commission_is_percentage'] != null
        ? (booking['commission_is_percentage'] == true)
        : (parsedNotes?['commission_is_percentage'] != null
            ? (parsedNotes!['commission_is_percentage'] == true)
            : AppConfigService.instance.commissionIsPercentage);

    final commFee = cIsPct ? base * (cRate / 100.0) : cRate;
    final calculated = (base - commFee).clamp(0.0, base);

    final double? dbEarnings = (booking['owner_earnings'] as num?)?.toDouble() ??
        (parsedNotes?['owner_earnings'] as num?)?.toDouble();

    // If valid owner_earnings exists and is consistent with slot price, prioritize it
    if (dbEarnings != null && dbEarnings > 0) {
      if (commFee > 0 && dbEarnings >= base) {
        // Historical booking where commission was not cut early before saving to DB
        return calculated;
      }
      if (slotPrice == null || slotPrice <= 0 || dbEarnings <= slotPrice) {
        return dbEarnings;
      }
    }

    return calculated;
  }

  /// Formats the earnings into a display string without unnecessary trailing decimals, e.g. "1200" or "1200.50".
  static String formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}
