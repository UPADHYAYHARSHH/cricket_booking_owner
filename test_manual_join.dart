import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final locationId = '12103983-28a8-4443-bb71-5f4b5090f7a6';
    final reviews = await client
          .from('location_reviews')
          .select()
          .limit(5);
    
    print('Reviews: $reviews');
    
    final userIds = reviews.map((r) => r['user_id']).where((id) => id != null).toSet().toList();
    print('User IDs: $userIds');
    
    if (userIds.isNotEmpty) {
       final users = await client.from('users').select('id, name, photo_url').filter('id', 'in', userIds);
       print('Users: $users');
    }
  } catch (e) {
    print('Failed: $e');
  }

  client.dispose();
  exit(0);
}
