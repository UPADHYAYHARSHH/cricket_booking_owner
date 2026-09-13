import os

filepath = 'lib/owner_booking/data/repositories/booking_repository_impl.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = """
    // Bypass RPC because it incorrectly sets status to 'confirmed' instead of 'approved'
    // Proceed directly to the fallback direct update

    // Direct update fallback if RPC didn't return or failed
    if (bookingData == null) {
      try {
        final updated = await _supabase
            .from('bookings')
            .update({
              'status': 'approved',
              'approved_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', bookingId)
            .select('*, grounds(name)')
            .maybeSingle();
        if (updated != null) {
          bookingData = Map<String, dynamic>.from(updated);
        }
      } catch (e) {
        print('[approveBooking] Direct update failed: $e');
      }
    }
"""

new_code = """
    try {
      final updated = await _supabase
          .from('bookings')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', bookingId)
          .select('*, grounds(name)')
          .maybeSingle();
      if (updated != null) {
        bookingData = Map<String, dynamic>.from(updated);
      }
    } catch (e) {
      print('[approveBooking] Direct update failed: $e');
    }
"""

content = content.replace(old_code, new_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed approveBooking logic")
