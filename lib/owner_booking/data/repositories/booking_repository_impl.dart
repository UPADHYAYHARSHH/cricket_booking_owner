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
}
