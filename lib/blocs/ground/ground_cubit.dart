import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

abstract class GroundState {}

class GroundInitial extends GroundState {}
class GroundLoading extends GroundState {}
class GroundLoaded extends GroundState {
  final List<dynamic> grounds;
  GroundLoaded(this.grounds);
}
class GroundError extends GroundState {
  final String message;
  GroundError(this.message);
}

class GroundCubit extends Cubit<GroundState> {
  GroundCubit() : super(GroundInitial());

  Future<void> fetchOwnerGrounds() async {
    emit(GroundLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('grounds')
          .select('''
            *,
            ground_images(image_url)
          ''')
          .eq('owner_id', user.id);
      
      // Map the response to include imageUrl for the UI to display easily
      final formattedData = (response as List).map((e) {
        return {
          ...e,
          'imageUrl': e['ground_images'] != null && e['ground_images'].isNotEmpty 
              ? e['ground_images'][0]['image_url'] 
              : 'https://placehold.co/600x400/FF6B00/FFFFFF/png?text=${e['name']}',
        };
      }).toList();

      emit(GroundLoaded(formattedData));
    } catch (e) {
      emit(GroundError(e.toString()));
    }
  }

  Future<void> registerGround({
    required String name,
    required String category,
    required String description,
    required String openingTime,
    required String closingTime,
    required List<String> imageUrls,
    required List<String> amenities,
    Map<String, int>? pricingOverrides,
  }) async {
    emit(GroundLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch Owner's address and location (as per user request)
      final ownerDetails = await Supabase.instance.client
          .from('owner_details')
          .select('address, latitude, longitude')
          .eq('id', user.id)
          .single();

      final String address = ownerDetails['address'];
      final double latitude = ownerDetails['latitude'];
      final double longitude = ownerDetails['longitude'];

      // 2. Insert Ground (removed non-existent imageUrl column)
      final groundResponse = await Supabase.instance.client.from('grounds').insert({
        'owner_id': user.id,
        'name': name,
        'categories': [category],
        'description': description,
        'price_per_hour': pricingOverrides?['weekday'] ?? 1000,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'amenities': amenities,
        'is_verified': false,
        'city': 'Default', // Can be refined from address later
        'pricing_config': pricingOverrides,
      }).select().single();

      final String groundId = groundResponse['id'];

      // 3. Insert Images into ground_images table
      if (imageUrls.isNotEmpty) {
        final List<Map<String, dynamic>> imagesToInsert = imageUrls.map((url) => {
          'ground_id': groundId,
          'image_url': url,
        }).toList();
        await Supabase.instance.client.from('ground_images').insert(imagesToInsert);
      }
      
      // 4. Automatically generate slots for the next 14 days
      await _generateSlots(groundId, openingTime, closingTime, pricingOverrides ?? {});

      fetchOwnerGrounds();
    } catch (e) {
      print("ERROR REGISTERING GROUND: $e");
      emit(GroundError(e.toString()));
    }
  }

  Future<void> _generateSlots(String groundId, String opening, String closing, Map<String, int> pricing) async {
    final List<Map<String, dynamic>> slotsToInsert = [];
    final int openHour = int.parse(opening.split(':')[0]);
    final int closeHour = int.parse(closing.split(':')[0]);
    
    for (int i = 0; i < 14; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      
      final int basePrice = isWeekend ? (pricing['weekend'] ?? 1200) : (pricing['weekday'] ?? 1000);

      for (int hour = openHour; hour < closeHour; hour++) {
        int finalPrice = basePrice;
        
        if (hour >= 6 && hour < 16) {
          finalPrice = pricing['morning'] ?? basePrice;
        } else if (hour >= 16 && hour < 20) {
          finalPrice = pricing['evening'] ?? basePrice;
        } else if (hour >= 20 || hour < 6) {
          finalPrice = pricing['night'] ?? basePrice;
        }

        slotsToInsert.add({
          'ground_id': groundId,
          'date': dateStr,
          'start_time': "${hour.toString().padLeft(2, '0')}:00",
          'end_time': "${(hour + 1).toString().padLeft(2, '0')}:00",
          'price': finalPrice,
          'status': 'available',
        });
      }
    }

    await Supabase.instance.client.from('slots').insert(slotsToInsert);
  }
}
