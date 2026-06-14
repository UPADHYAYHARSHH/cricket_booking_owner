import 'package:supabase/supabase.dart';

void main() async {
  const supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final ownersData = await client.from('owner_details').select();
    print('Found ${ownersData.length} owners.');

    List<Map<String, dynamic>> allGroundsToInsert = [];

    for (var ownerData in ownersData) {
      final ownerId = ownerData['id'];
      final groundConfig = ownerData['ground_config'] as Map<String, dynamic>?;
      final amenitiesConfig = ownerData['amenities_config'] as Map<String, dynamic>? ?? {};
      final slotConfig = ownerData['slot_config'] as Map<String, dynamic>? ?? {};

      if (groundConfig != null) {
        groundConfig.forEach((sportKey, sportDetails) {
          if (sportDetails is Map<String, dynamic>) {
            final numCourtsRaw = sportDetails['num_courts'];
            int numCourts = 1;
            if (numCourtsRaw is int) numCourts = numCourtsRaw;
            if (numCourtsRaw is String) numCourts = int.tryParse(numCourtsRaw) ?? 1;

            final courtNames = sportDetails['court_names'] as List<dynamic>? ?? [];

            for (int i = 0; i < numCourts; i++) {
              String courtName = (courtNames.length > i) ? courtNames[i] : "$sportKey Court ${i + 1}";
              
              String formatTime(String? t) {
                if (t == null) return '06:00:00';
                try {
                  final tClean = t.replaceAll(RegExp(r'[^0-9:AMPMapm]'), '');
                  bool isPM = tClean.toLowerCase().contains('pm');
                  String timeStr = tClean.replaceAll(RegExp(r'[AMPMapm]'), '').trim();
                  List<String> parts = timeStr.split(':');
                  int hour = int.parse(parts[0]);
                  int min = parts.length > 1 ? int.parse(parts[1]) : 0;
                  if (isPM && hour != 12) hour += 12;
                  if (!isPM && hour == 12) hour = 0;
                  return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:00';
                } catch (_) {
                  return '06:00:00';
                }
              }

              // Try to get price
              int price = 800;
              try {
                final pricing = ownerData['pricing_config']?[sportKey]?['weekday']?['off_peak'];
                if (pricing != null) price = int.tryParse(pricing.toString()) ?? 800;
              } catch (_) {}

              List<String> mapCategories(String key) {
                if (key == 'box_cricket') return ['Cricket', 'Box Cricket'];
                if (key == 'football') return ['Football'];
                if (key == 'pickleball') return ['Pickleball'];
                if (key == 'volleyball') return ['Volleyball'];
                if (key == 'basketball') return ['Basketball'];
                if (key == 'badminton') return ['Badminton'];
                return [key];
              }

              allGroundsToInsert.add({
                'owner_id': ownerId,
                'name': courtName,
                'description': ownerData['venue_tagline'] ?? '',
                'address': ownerData['address'] ?? '',
                'city': ownerData['city'] ?? '',
                'state': ownerData['state'] ?? '',
                'opening_time': formatTime(slotConfig['opening_time']),
                'closing_time': formatTime(slotConfig['closing_time']),
                'ground_type': sportKey,
                'categories': mapCategories(sportKey),
                'turf_type': sportDetails['surface_type'] ?? sportDetails['pitch_type'] ?? '',
                'players_allowed': int.tryParse(sportDetails['players_per_side']?.toString() ?? '12') ?? 12,
                'is_indoor': ownerData['venue_category'] == 'Indoor',
                'has_parking': amenitiesConfig['parking'] == true,
                'has_washroom': amenitiesConfig['washrooms'] == true,
                'has_floodlights': sportDetails['floodlights'] != null && sportDetails['floodlights'].toString().toLowerCase().contains('yes'),
                'has_drinking_water': amenitiesConfig['drinking_water'] == true,
                'is_available': true,
                'price_per_hour': price,
                'rating': 4.5,
                'total_reviews': 0,
                'slot_duration': 60,
                'latitude': ownerData['latitude'] ?? 23.05,
                'longitude': ownerData['longitude'] ?? 72.55,
              });
            }
          }
        });
      }
    }

    if (allGroundsToInsert.isNotEmpty) {
      await client.from('favorites').delete().neq('id', '00000000-0000-0000-0000-000000000000'); // Delete favorites first
      await client.from('bookings').delete().neq('id', '00000000-0000-0000-0000-000000000000'); // Delete bookings second
      await client.from('grounds').delete().neq('id', '00000000-0000-0000-0000-000000000000'); // Delete grounds third
      await client.from('grounds').insert(allGroundsToInsert);
      print('Successfully inserted ${allGroundsToInsert.length} grounds.');
      
      // Now let's create a couple of dummy bookings for these grounds to test the dashboard UI
      final insertedGrounds = await client.from('grounds').select('id, owner_id, name, ground_type');
      
      List<Map<String, dynamic>> dummyBookings = [];
      for (var ground in insertedGrounds) {
        // Create 2 bookings for each ground
        dummyBookings.add({
          'user_id': 'cg05tMVTiSYELxFVP74Rl0sJkZt2', // dummy user
          'ground_id': ground['id'],
          'booking_date': DateTime.now().toIso8601String(),
          'amount': 800,
          'total_amount': 800,
          'status': 'confirmed',
          'booking_status': 'confirmed',
          'payment_status': 'paid',
          'period': '07:00 AM - 08:00 AM',
          'slot_time': DateTime.now().toIso8601String(),
          'sport_name': ground['ground_type'] ?? 'cricket',
          'razorpay_order_id': 'dummy_order',
          'razorpay_payment_id': 'dummy_payment',
          'razorpay_signature': 'dummy_sig'
        });
        
        dummyBookings.add({
          'user_id': 'cg05tMVTiSYELxFVP74Rl0sJkZt2', // dummy user
          'ground_id': ground['id'],
          'booking_date': DateTime.now().toIso8601String(),
          'amount': 1200,
          'total_amount': 1200,
          'status': 'pending',
          'booking_status': 'pending',
          'payment_status': 'pending',
          'period': '06:00 PM - 07:00 PM',
          'slot_time': DateTime.now().add(const Duration(hours: 10)).toIso8601String(),
          'sport_name': ground['ground_type'] ?? 'cricket',
          'razorpay_order_id': 'dummy_order_2',
          'razorpay_payment_id': 'dummy_payment_2',
          'razorpay_signature': 'dummy_sig_2'
        });
      }
      
      if (dummyBookings.isNotEmpty) {
         await client.from('bookings').delete().neq('id', '00000000-0000-0000-0000-000000000000');
         await client.from('bookings').insert(dummyBookings);
         print('Successfully inserted ${dummyBookings.length} dummy bookings.');
      }
      
    } else {
      print('No grounds to insert based on owner_details configurations.');
    }
  } catch (e) {
    print('Error: $e');
  }
}
