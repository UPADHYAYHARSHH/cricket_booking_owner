class BookingIdUtil {
  static String getShortId(String fullId) {
    if (fullId.isEmpty) return "000";

    // For Razorpay / Cashfree order IDs
    if (fullId.startsWith('order_')) {
      return fullId
          .substring(6, fullId.length > 12 ? 12 : fullId.length)
          .toUpperCase();
    }

    // For UUIDs (e.g. 123e4567-e89b-12d3-a456-426614174000)
    final clean = fullId.replaceAll('-', '');
    if (clean.length > 6) {
      return clean.substring(0, 6).toUpperCase();
    }

    return clean.toUpperCase();
  }

  static String formatDisplayId(int displayId) {
    return displayId.toString().padLeft(3, '0');
  }

  static String formatBookingId(dynamic rawDisplayId, dynamic rawId) {
    if (rawDisplayId != null) {
      final parsed = int.tryParse(rawDisplayId.toString());
      if (parsed != null && parsed > 0) {
        return parsed.toString().padLeft(3, '0');
      }
      final s = rawDisplayId.toString().trim();
      if (s.isNotEmpty && s != '0') {
        return s;
      }
    }
    return getShortId((rawId ?? '').toString());
  }
}
