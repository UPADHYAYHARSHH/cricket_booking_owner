import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/ground_repository.dart';

class GroundRepositoryImpl implements GroundRepository {
  final SupabaseClient _supabase;

  GroundRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId) async {
    List<String> activeSportIdentifiers = [];
    try {
      final sportsResponse = await _supabase.from('sports').select('slug, name').eq('is_active', true);
      for (var s in sportsResponse as List) {
        if (s['slug'] != null) activeSportIdentifiers.add(s['slug'].toString().toLowerCase());
        if (s['name'] != null) activeSportIdentifiers.add(s['name'].toString().toLowerCase());
      }
    } catch (e) {
      // Ignore
    }

    final response = await _supabase
        .from('grounds')
        .select('*, ground_images(image_url)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    final grounds = (response as List).map<Map<String, dynamic>>((e) {
      return {
        ...e as Map<String, dynamic>,
        'imageUrl':
            (e['ground_images'] != null &&
                (e['ground_images'] as List).isNotEmpty)
            ? e['ground_images'][0]['image_url']
            : 'https://placehold.co/600x400/0B8457/FFFFFF/png?text=${Uri.encodeComponent(e['name'] ?? 'Ground')}',
      };
    }).toList();

    if (activeSportIdentifiers.isNotEmpty) {
      return grounds.where((g) {
        final category = g['category']?.toString().toLowerCase() ?? '';
        final groundType = g['ground_type']?.toString().toLowerCase() ?? '';
        final categories = (g['categories'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        
        bool hasMatch = activeSportIdentifiers.contains(category) || 
                        activeSportIdentifiers.contains(groundType);
                        
        for (var c in categories) {
          if (activeSportIdentifiers.contains(c)) {
            hasMatch = true;
            break;
          }
        }
        return hasMatch;
      }).toList();
    }
    
    return grounds;
  }

  @override
  Future<List<Map<String, dynamic>>> getGroundsForLocation(
    String locationId,
  ) async {
    List<String> activeSportIdentifiers = [];
    try {
      final sportsResponse = await _supabase.from('sports').select('slug, name').eq('is_active', true);
      for (var s in sportsResponse as List) {
        if (s['slug'] != null) activeSportIdentifiers.add(s['slug'].toString().toLowerCase());
        if (s['name'] != null) activeSportIdentifiers.add(s['name'].toString().toLowerCase());
      }
    } catch (e) {
      // Ignore
    }

    final response = await _supabase
        .from('grounds')
        .select('*, ground_images(image_url)')
        .eq('location_id', locationId)
        .order('created_at', ascending: false);

    final grounds = (response as List).map<Map<String, dynamic>>((e) {
      return {
        ...e as Map<String, dynamic>,
        'imageUrl':
            (e['ground_images'] != null &&
                (e['ground_images'] as List).isNotEmpty)
            ? e['ground_images'][0]['image_url']
            : 'https://placehold.co/600x400/0B8457/FFFFFF/png?text=${Uri.encodeComponent(e['name'] ?? 'Ground')}',
      };
    }).toList();

    if (activeSportIdentifiers.isNotEmpty) {
      return grounds.where((g) {
        final category = g['category']?.toString().toLowerCase() ?? '';
        final groundType = g['ground_type']?.toString().toLowerCase() ?? '';
        final categories = (g['categories'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        
        bool hasMatch = activeSportIdentifiers.contains(category) || 
                        activeSportIdentifiers.contains(groundType);
                        
        for (var c in categories) {
          if (activeSportIdentifiers.contains(c)) {
            hasMatch = true;
            break;
          }
        }
        return hasMatch;
      }).toList();
    }
    
    return grounds;
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
  Future<void> toggleGroundAvailability({
    required String groundId,
    required bool isAvailable,
  }) async {
    await _supabase.rpc(
      'toggle_ground_availability',
      params: {
        'p_ground_id': groundId,
        'p_is_available': isAvailable,
      },
    );
  }
}
