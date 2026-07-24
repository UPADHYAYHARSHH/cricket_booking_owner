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
        'imageUrl':
            (e['ground_images'] != null &&
                (e['ground_images'] as List).isNotEmpty)
            ? e['ground_images'][0]['image_url']
            : 'https://placehold.co/600x400/0B8457/FFFFFF/png?text=${Uri.encodeComponent(e['name'] ?? 'Ground')}',
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getGroundsForLocation(
    String locationId,
  ) async {
    final response = await _supabase
        .from('grounds')
        .select('*, ground_images(image_url)')
        .eq('location_id', locationId)
        .order('created_at', ascending: false);

    return (response as List).map<Map<String, dynamic>>((e) {
      return {
        ...e as Map<String, dynamic>,
        'imageUrl':
            (e['ground_images'] != null &&
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
    required String category,
    required String openingTime,
    required String closingTime,
    required List<String> operatingDays,
    required String slotDuration,
    Map<String, int>? pricingOverrides,
  }) async {
    final groundResponse = await _supabase.rpc(
      'register_ground',
      params: {
        'p_owner_id': ownerId,
        'p_location_id': locationId,
        'p_category': category,
        'p_price_per_hour': pricingOverrides?['weekday'] ?? 600,
        'p_weekend_price': pricingOverrides?['weekend'] ?? 800,
        'p_opening_time': openingTime,
        'p_closing_time': closingTime,
        'p_operating_days': operatingDays,
        'p_slot_duration': slotDuration,
      },
    );

    final groundId = (groundResponse as Map<String, dynamic>)['id'] as String;
    return groundId;
  }

  @override
  Future<void> updateGround({
    required String groundId,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.rpc(
      'update_ground',
      params: {
        'p_ground_id': groundId,
        'p_category': data['category'] ?? '',
        'p_price_per_hour': data['price_per_hour'] ?? 600,
        'p_weekend_price': data['weekend_price'] ?? 800,
        'p_opening_time': data['opening_time'] ?? '06:00',
        'p_closing_time': data['closing_time'] ?? '23:00',
        'p_operating_days': data['operating_days'] ?? <String>[],
        'p_slot_duration': data['slot_duration'] ?? '1 Hour',
        'p_is_available': data['is_available'] ?? true,
      },
    );
  }

  @override
  Future<void> generateSlots(
    String groundId,
    String openingTime,
    String closingTime,
    Map<String, int> pricing,
    List<String> operatingDays,
    String slotDuration,
  ) async {
    await _supabase.rpc(
      'generate_ground_slots',
      params: {
        'p_ground_id': groundId,
        'p_opening_time': openingTime,
        'p_closing_time': closingTime,
        'p_weekday_price': pricing['weekday'] ?? 600,
        'p_weekend_price': pricing['weekend'] ?? 800,
        'p_slot_duration': slotDuration,
        'p_operating_days': operatingDays,
      },
    );
  }

  @override
  Future<void> regenerateFutureSlots(
    String groundId,
    String openingTime,
    String closingTime,
    Map<String, int> pricing,
  ) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Delete only available slots from tomorrow onwards so we don't cancel bookings.
    await _supabase
        .from('slots')
        .delete()
        .eq('ground_id', groundId)
        .eq('status', 'available')
        .gte('date', todayStr);

    // fetch slot duration and operating days from ground row so regeneration
    // uses the same configuration the ground currently has
    final groundResp = await _supabase
        .from('grounds')
        .select('slot_duration, operating_days')
        .eq('id', groundId)
        .maybeSingle();

    final slotDuration =
        (groundResp != null && groundResp['slot_duration'] != null)
        ? groundResp['slot_duration'] as String
        : '1 Hour';

    final operatingDays =
        (groundResp != null && groundResp['operating_days'] != null)
        ? List<String>.from(groundResp['operating_days'] as List)
        : <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    await generateSlots(
      groundId,
      openingTime,
      closingTime,
      pricing,
      operatingDays,
      slotDuration,
    );
  }
}
