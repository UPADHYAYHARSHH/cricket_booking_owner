import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final response = await client.from('owner_details').select().order('created_at', ascending: false).limit(3);
    for (var r in response) {
      print("User ID: ${r['id']}, Name: ${r['owner_name']}, Phone: ${r['phone']}, City: ${r['city']}, Business: ${r['business_name']}, Venue: ${r['venue_name']}");
    }
  } catch (e) {
    print('Error: $e');
  }
}
