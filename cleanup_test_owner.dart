import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://qcybnzopffyzmpiaxwbc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg',
  );

  final testOwnerId = '7fd567b7-4371-49ff-aed6-4c77e1e58f6e';

  try {
    // Get grounds for test owner
    final grounds = await client.from('grounds').select('id').eq('owner_id', testOwnerId);
    
    if (grounds.isEmpty) {
      print('No grounds found for test@gmail.com');
      return;
    }

    final groundIds = grounds.map((g) => g['id'] as String).toList();
    print('Found ${groundIds.length} grounds to delete.');

    // Delete dependencies first
    await client.from('favorites').delete().filter('ground_id', 'in', groundIds);
    await client.from('bookings').delete().filter('ground_id', 'in', groundIds);
    
    // Delete grounds
    await client.from('grounds').delete().eq('owner_id', testOwnerId);
    
    print('Successfully deleted all grounds and associated data for test@gmail.com');
  } catch (e) {
    print('Error: $e');
  }
}
