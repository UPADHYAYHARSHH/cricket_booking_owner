import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/slot_repository.dart';

class SlotRepositoryImpl implements SlotRepository {
  final SupabaseClient _supabase;

  SlotRepositoryImpl(this._supabase);

  @override
  Future<Map<String, dynamic>?> getOwnerDetails(String userId) async {
    return await _supabase
        .from('owner_details')
        .select('venue_name')
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId) async {
    final response = await _supabase
        .from('grounds')
        .select('id, name, location_id, category, ground_type, opening_time, closing_time, slot_duration, price_per_hour, weekend_price, created_at')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchBookingsForGround(String groundId) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('ground_id', groundId)
        .map((list) => List<Map<String, dynamic>>.from(list));
  }

  @override
  Future<Map<String, dynamic>> insertOwnerBooking({
    required String groundId,
    required String slotTime,
    required DateTime localStartTime,
    required int price,
    required String sportName,
    required String period,
    String? note,
  }) async {
    final result = await _supabase.rpc('save_owner_booking', params: {
      'p_ground_id': groundId,
      'p_slot_time': slotTime,
      'p_amount': price,
      'p_sport_name': sportName,
      'p_period': period,
      'p_notes': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    });
    
    // Sync to slots table for the Booking App
    final formattedDate = "${localStartTime.year}-${localStartTime.month.toString().padLeft(2, '0')}-${localStartTime.day.toString().padLeft(2, '0')}";
    final formattedStartTime = "${localStartTime.hour.toString().padLeft(2, '0')}:${localStartTime.minute.toString().padLeft(2, '0')}:00";
    
    await _supabase.rpc('upsert_slot', params: {
      'p_ground_id': groundId,
      'p_date': formattedDate,
      'p_start_time': formattedStartTime,
      'p_status': 'booked',
      'p_price': price,
    });

    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<void> deleteOwnerBooking({
    required String bookingId,
    required String groundId,
    required DateTime localStartTime,
    required int defaultPrice,
  }) async {
    await _supabase.rpc('delete_owner_booking', params: {
      'p_booking_id': bookingId,
    });
    
    // Sync to slots table for the Booking App
    final formattedDate = "${localStartTime.year}-${localStartTime.month.toString().padLeft(2, '0')}-${localStartTime.day.toString().padLeft(2, '0')}";
    final formattedStartTime = "${localStartTime.hour.toString().padLeft(2, '0')}:${localStartTime.minute.toString().padLeft(2, '0')}:00";
    
    await _supabase.rpc('upsert_slot', params: {
      'p_ground_id': groundId,
      'p_date': formattedDate,
      'p_start_time': formattedStartTime,
      'p_status': 'available',
      'p_price': defaultPrice,
    });
  }
}
