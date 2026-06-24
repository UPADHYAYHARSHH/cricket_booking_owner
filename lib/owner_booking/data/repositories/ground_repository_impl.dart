import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/ground_repository.dart';

class GroundRepositoryImpl implements GroundRepository {
  final SupabaseClient _supabase;

  GroundRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId) async {
    final response = await _supabase
        .from('grounds')
        .select('*, ground_images(image_url)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    return (response as List).map<Map<String, dynamic>>((e) {
      return {
        ...e as Map<String, dynamic>,
        'imageUrl': (e['ground_images'] != null &&
                (e['ground_images'] as List).isNotEmpty)
            ? e['ground_images'][0]['image_url']
            : 'https://placehold.co/600x400/0B8457/FFFFFF/png?text=${Uri.encodeComponent(e['name'] ?? 'Ground')}',
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getGroundsForLocation(
      String locationId) async {
    final response = await _supabase
        .from('grounds')
        .select('*, ground_images(image_url)')
        .eq('location_id', locationId)
        .order('created_at', ascending: false);

    return (response as List).map<Map<String, dynamic>>((e) {
      return {
        ...e as Map<String, dynamic>,
        'imageUrl': (e['ground_images'] != null &&
                (e['ground_images'] as List).isNotEmpty)
            ? e['ground_images'][0]['image_url']
            : 'https://placehold.co/600x400/0B8457/FFFFFF/png?text=${Uri.encodeComponent(e['name'] ?? 'Ground')}',
      };
    }).toList();
  }

  @override
  Future<String> registerGround({
    required String ownerId,
    required String locationId,
    required String name,
    required String category,
    required String description,
    required String openingTime,
    required String closingTime,
    required List<String> imageUrls,
    Map<String, int>? pricingOverrides,
  }) async {
    final groundResponse = await _supabase
        .from('grounds')
        .insert({
          'owner_id': ownerId,
          'location_id': locationId,
          'name': name,
          'category': category,
          'description': description,
          'price_per_hour': pricingOverrides?['weekday'] ?? 600,
          'weekend_price': pricingOverrides?['weekend'] ?? 800,
          'opening_time': openingTime,
          'closing_time': closingTime,
        })
        .select()
        .single();

    final groundId = groundResponse['id'] as String;

    if (imageUrls.isNotEmpty) {
      await insertGroundImages(groundId, imageUrls);
    }

    return groundId;
  }

  @override
  Future<void> updateGround({
    required String groundId,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('grounds').update(data).eq('id', groundId);
  }

  @override
  Future<void> insertGroundImages(
      String groundId, List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;
    await _supabase.from('ground_images').insert(
          imageUrls
              .map((url) => {'ground_id': groundId, 'image_url': url})
              .toList(),
        );
  }

  @override
  Future<void> replaceGroundImages(
      String groundId, List<String> imageUrls) async {
    await _supabase.from('ground_images').delete().eq('ground_id', groundId);
    await insertGroundImages(groundId, imageUrls);
  }

  @override
  Future<void> generateSlots(
    String groundId,
    String openingTime,
    String closingTime,
    Map<String, int> pricing,
  ) async {
    final List<Map<String, dynamic>> slotsToInsert = [];
    final openHour = _parseHour(openingTime);
    final closeHour = _parseHour(closingTime);

    if (openHour == null || closeHour == null || openHour >= closeHour) return;

    for (int i = 0; i < 14; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;

      final slotPrice =
          isWeekend ? (pricing['weekend'] ?? 800) : (pricing['weekday'] ?? 600);

      for (int hour = openHour; hour < closeHour; hour++) {
        slotsToInsert.add({
          'ground_id': groundId,
          'date': dateStr,
          'start_time': '${hour.toString().padLeft(2, '0')}:00',
          'end_time': '${(hour + 1).toString().padLeft(2, '0')}:00',
          'price': slotPrice,
          'status': 'available',
        });
      }
    }

    if (slotsToInsert.isNotEmpty) {
      await _supabase.from('slots').insert(slotsToInsert);
    }
  }

  @override
  Future<void> regenerateFutureSlots(
    String groundId,
    String openingTime,
    String closingTime,
    Map<String, int> pricing,
  ) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Delete only available slots from tomorrow onwards so we don't cancel bookings.
    await _supabase
        .from('slots')
        .delete()
        .eq('ground_id', groundId)
        .eq('status', 'available')
        .gte('date', todayStr);

    await generateSlots(groundId, openingTime, closingTime, pricing);
  }

  int? _parseHour(String time) {
    try {
      return int.parse(time.split(':')[0]);
    } catch (_) {
      return null;
    }
  }
}
