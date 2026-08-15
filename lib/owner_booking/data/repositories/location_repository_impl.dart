import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/location_repository.dart';
import 'dart:io' as dart_io;

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
    required String privacyPolicy,
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
          'privacy_policy': privacyPolicy,
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

  @override
  Future<String> uploadLocationDocument({
    required String ownerId,
    required String locationId,
    required String filePath,
  }) async {
    final ext = filePath.contains('.') && !filePath.startsWith('blob:')
        ? filePath.split('.').last
        : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = '$ownerId/locations/$locationId/$fileName';

    if (kIsWeb) {
      final response = await http.get(Uri.parse(filePath));
      await _supabase.storage.from('venue_media').uploadBinary(
        storagePath,
        response.bodyBytes,
      );
    } else {
      final file = dart_io.File(filePath);
      await _supabase.storage.from('venue_media').upload(storagePath, file);
    }
    
    return _supabase.storage.from('venue_media').getPublicUrl(storagePath);
  }

  @override
  Future<void> syncLocationImages({
    required String ownerId,
    required String locationId,
    required List<String> allImages,
    required List<String> newImagesToUpload,
  }) async {
    // Note: This assumes a `location_images` table exists.
    // If it doesn't exist, this will throw an error. The user needs to create it.
    
    // 1. Upload new images
    List<String> finalUrls = [];
    for (String img in allImages) {
      if (img.startsWith('http')) {
        finalUrls.add(img);
      } else {
        final url = await uploadLocationDocument(
            ownerId: ownerId, locationId: locationId, filePath: img);
        finalUrls.add(url);
      }
    }

    // 2. Delete existing images from DB
    await _supabase.from('location_images').delete().eq('location_id', locationId);

    // 3. Insert all images again to keep order
    if (finalUrls.isNotEmpty) {
      final inserts = finalUrls.map((url) => {
            'location_id': locationId,
            'image_url': url,
          }).toList();
      await _supabase.from('location_images').insert(inserts);
    }
  }
}
