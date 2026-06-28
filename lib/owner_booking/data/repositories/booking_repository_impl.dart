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
        .eq('locations.documents_verified', true)
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
      final response = await _supabase
          .from('users')
          .select()
          .filter('id', 'in', userIds);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
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
          .filter('user_id', 'in', userIds);
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
        .eq('grounds.locations.documents_verified', true)
        .eq('grounds.locations.is_active', true)
        .filter('grounds.locations.deleted_at', 'is', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
