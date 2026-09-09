import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final SupabaseClient _supabase;

  BookingRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId) async {
    // Only grounds whose location has been approved by the admin dashboard
    // and is currently active should count towards dashboard stats.
    final response = await _supabase
        .from('grounds')
        .select('id, name, location_id, locations!inner(documents_verified, is_active, deleted_at)')
        .eq('owner_id', ownerId)
        .eq('locations.is_active', true)
        .filter('locations.deleted_at', 'is', null);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchBookingsForGrounds(
      List<Object> groundIds) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .inFilter('ground_id', groundIds)
        .order('created_at', ascending: false)
        .map((list) => List<Map<String, dynamic>>.from(list));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      // Use get_user_profile RPC to bypass RLS on the users table
      final List<Map<String, dynamic>> users = [];
      for (final id in userIds) {
        try {
          final data = await _supabase.rpc('get_user_profile', params: {'p_id': id});
          if (data != null) {
            // The RPC might return a Map or throw if not found
            if (data is Map) {
              final typedData = Map<String, dynamic>.from(data);
              // Ensure the id is included so userMap works
              typedData['id'] = id;
              users.add(typedData);
            }
          }
        } catch (e) {
          print('[fetchUsers] Error fetching profile for $id: $e');
        }
      }
      
      print('[fetchUsers] Success! Found ${users.length} users for IDs: $userIds');
      print('[fetchUsers] Data: $users');
      return users;
    } catch (e) {
      print('[fetchUsers] ERROR fetching users: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserPastBookings(
      List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      final response = await _supabase
          .from('bookings')
          .select('user_id')
          .inFilter('user_id', userIds);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getBookingForCheckIn(String bookingId) async {
    return await _supabase
        .from('bookings')
        .select('*, grounds(name, owner_id, category)')
        .eq('id', bookingId)
        .maybeSingle();
  }

  @override
  Future<void> checkInBooking(String bookingId) async {
    await _supabase.from('bookings').update({
      'checked_in': true,
      'checked_in_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  @override
  Future<void> sendCheckInNotification({
    required String userId,
    required String bookingId,
    required String groundName,
    required String checkInTime,
    required String checkInDate,
  }) async {
    try {
      // Insert notification into the notifications table
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'Check-In Confirmed',
        'message': 'Your booking at $groundName has been checked in at $checkInTime on $checkInDate.',
        'type': 'booking_checked_in',
        'data': {
          'booking_id': bookingId,
          'ground_name': groundName,
          'check_in_time': checkInTime,
          'check_in_date': checkInDate,
        },
        'is_read': false,
      });
    } catch (e) {
      // Don't fail check-in if notification fails
      print('Failed to send check-in notification: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOwnerBookingsWithDetails(
      String ownerId) async {
    // Scoped the same way as getOwnerGrounds: only count bookings whose
    // ground belongs to an approved/active/non-deleted location, so the
    // revenue report and the dashboard agree on the same set of bookings.
    final response = await _supabase
        .from('bookings')
        .select(
            '*, grounds!inner(name, category, location_id, owner_id, locations!inner(documents_verified, is_active, deleted_at))')
        .eq('grounds.owner_id', ownerId)
        .eq('grounds.locations.is_active', true)
        .filter('grounds.locations.deleted_at', 'is', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> approveBooking(String bookingId) async {
    try {
      await _supabase.rpc('approve_booking', params: {
        'p_booking_id': bookingId,
      });
    } catch (e) {
      // Fallback: direct update if RPC is unavailable
      final updated = await _supabase
          .from('bookings')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .select('*, grounds(name)')
          .maybeSingle();

      if (updated != null && updated['user_id'] != null) {
        final groundName = updated['grounds']?['name'] ?? 'the venue';
        try {
          await _supabase.from('notifications').insert({
            'user_id': updated['user_id'],
            'title': 'Booking Approved! 🎉 Pay in 45 Mins',
            'message': 'Your booking request for $groundName has been approved! Please complete payment within 45 minutes.',
            'type': 'booking_approved',
            'data': {
              'booking_id': bookingId,
              'ground_id': updated['ground_id'],
              'amount': updated['amount'],
              'action': 'payment_required',
            },
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> deleteOrExpireBooking(String bookingId, {String reason = 'declined_by_owner'}) async {
    try {
      await _supabase.rpc('delete_or_expire_booking', params: {
        'p_booking_id': bookingId,
        'p_reason': reason,
      });
    } catch (e) {
      // Fallback: fetch details, delete booking, free slots and notify user
      try {
        final booking = await _supabase
            .from('bookings')
            .select('*, grounds(name, owner_id)')
            .eq('id', bookingId)
            .maybeSingle();

        if (booking != null) {
          final userId = booking['user_id'];
          final groundName = booking['grounds']?['name'] ?? 'the ground';
          final groundId = booking['ground_id'];
          final slotTimeStr = booking['slot_time']?.toString();

          // Free slots
          if (slotTimeStr != null && groundId != null) {
            final slotDate = DateTime.tryParse(slotTimeStr);
            if (slotDate != null) {
              final dateStr = "${slotDate.year}-${slotDate.month.toString().padLeft(2, '0')}-${slotDate.day.toString().padLeft(2, '0')}";
              await _supabase
                  .from('slots')
                  .update({'status': 'available'})
                  .match({'ground_id': groundId, 'date': dateStr});
            }
          }

          // Delete booking
          await _supabase.from('bookings').delete().eq('id', bookingId);

          // Insert notification
          if (userId != null) {
            String title = 'Booking Request Declined';
            String msg = 'Your booking request for $groundName was declined by the owner.';
            if (reason == 'expired_owner_timeout') {
              title = 'Booking Request Expired';
              msg = 'Your booking request for $groundName expired as the owner did not respond in 45 minutes.';
            } else if (reason == 'expired_user_payment_timeout') {
              title = 'Booking Cancelled (Payment Timeout)';
              msg = 'Your booking for $groundName was cancelled as payment was not completed in 45 minutes.';
            }

            await _supabase.from('notifications').insert({
              'user_id': userId,
              'title': title,
              'message': msg,
              'type': 'booking_cancelled',
              'data': {'ground_name': groundName, 'reason': reason},
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      } catch (_) {}
    }
  }
}
