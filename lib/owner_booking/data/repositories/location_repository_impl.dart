import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final SupabaseClient _supabase;

  LocationRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getOwnerLocations(String ownerId) async {
    final response = await _supabase
        .from('locations')
        .select()
        .eq('owner_id', ownerId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<String> registerLocation({
    required String ownerId,
    required String address,
    required String city,
    required String description,
    required String googleMapsLink,
    required double latitude,
    required double longitude,
    required List<String> amenities,
  }) async {
    final response = await _supabase
        .from('locations')
        .insert({
          'owner_id': ownerId,
          'address': address,
          'city': city,
          'description': description,
          'google_maps_link': googleMapsLink,
          'latitude': latitude,
          'longitude': longitude,
          'amenities': amenities,
        })
        .select()
        .single();

    return response['id'] as String;
  }

  @override
  Future<void> updateLocation({
    required String locationId,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('locations').update(data).eq('id', locationId);
  }

  @override
  Future<void> softDeleteLocation(String locationId) async {
    await _supabase
        .from('locations')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', locationId);
  }
}
