import os

filepath = 'lib/owner_booking/data/repositories/booking_repository_impl.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add notifyUserToPay inside BookingRepositoryImpl
new_method = """
  Future<void> notifyUserToPay(String bookingId) async {
    try {
      final fetched = await _supabase.from('bookings').select('*, grounds(name, owner_id)').eq('id', bookingId).maybeSingle();
      if (fetched == null) return;
      
      final bookingData = Map<String, dynamic>.from(fetched);
      final userId = bookingData['user_id']?.toString();
      if (userId == null || userId.isEmpty) return;

      String groundName = 'the venue';
      if (bookingData['grounds'] is Map && bookingData['grounds']['name'] != null) {
        groundName = bookingData['grounds']['name'];
      }

      final inserted = await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'Payment Reminder \u23f0',
        'message': 'Friendly reminder: Please complete payment for your booking at $groundName within the 45-minute window to secure your slot!',
        'type': 'booking_approved',
        'data': {
          'booking_id': bookingId,
          'ground_id': bookingData['ground_id'],
          'amount': bookingData['amount'],
          'action': 'payment_required'
        },
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select('id').maybeSingle();

      if (inserted != null && inserted['id'] != null) {
        _invokePushNotification(inserted['id'].toString());
      }
    } catch (e) {
      print('[notifyUserToPay] Error: $e');
    }
  }

  @override
  Future<void> deleteOrExpireBooking(
"""

content = content.replace("@override\n  Future<void> deleteOrExpireBooking(", new_method)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Added notifyUserToPay to BookingRepositoryImpl")
