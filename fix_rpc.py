import os

filepath = 'lib/owner_booking/data/repositories/booking_repository_impl.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Comment out the RPC block in approveBooking
old_rpc = """
    try {
      final res = await _supabase.rpc('approve_booking', params: {
        'p_booking_id': bookingId,
      });
      if (res != null) {
        if (res is Map) {
          bookingData = Map<String, dynamic>.from(res);
        } else if (res is String) {
          try {
            final decoded = jsonDecode(res);
            if (decoded is Map) bookingData = Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
      }
    } catch (e) {
      print('[approveBooking] RPC failed, falling back to direct update: $e');
    }
"""

new_rpc = """
    // Bypass RPC because it incorrectly sets status to 'confirmed' instead of 'approved'
    // Proceed directly to the fallback direct update
"""

if old_rpc.strip() in content:
    content = content.replace(old_rpc.strip(), new_rpc.strip())
else:
    # Use regex to find and replace the block
    import re
    content = re.sub(r"try\s*\{\s*final res = await _supabase\.rpc\('approve_booking'[\s\S]*?falling back to direct update: \$e'\);\s*\}", new_rpc.strip(), content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Removed RPC call")
