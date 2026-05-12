class IdUtil {
  static String getShortId(String fullId) {
    if (fullId.isEmpty) return "000";
    
    // For Razorpay order IDs (e.g. order_IluGWxBm9U8zJ8)
    if (fullId.startsWith('order_')) {
      return fullId.substring(6, fullId.length > 12 ? 12 : fullId.length).toUpperCase();
    }
    
    // For UUIDs (e.g. 123e4567-e89b-12d3-a456-426614174000)
    if (fullId.contains('-')) {
      final parts = fullId.split('-');
      // Return first 6 characters to make it look like a PNR/Ticket No.
      if (parts.first.length >= 6) {
        return parts.first.substring(0, 6).toUpperCase();
      }
      return parts.first.toUpperCase();
    }
    
    // Fallback
    if (fullId.length > 6) {
      return fullId.substring(0, 6).toUpperCase();
    }
    
    return fullId.toUpperCase();
  }

  static String formatDisplayId(int displayId) {
    return displayId.toString().padLeft(3, '0');
  }
}
