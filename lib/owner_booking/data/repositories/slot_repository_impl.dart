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
        .select()
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
}
