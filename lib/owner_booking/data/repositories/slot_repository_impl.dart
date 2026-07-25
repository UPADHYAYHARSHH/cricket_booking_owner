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
    required int price,
    required String sportName,
    required String period,
    String? note,
  }) async {
    final data = {
      'ground_id': groundId,
      'slot_time': slotTime,
      'amount': price,
      'status': 'confirmed',
      'sport_name': sportName,
      'period': period,
      'checked_in': false,
    };
    
    if (note != null && note.trim().isNotEmpty) {
      data['notes'] = note.trim();
    }

    final result = await _supabase
        .from('bookings')
        .insert(data)
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<void> deleteOwnerBooking(String bookingId) async {
    await _supabase.from('bookings').delete().eq('id', bookingId);
  }
}
