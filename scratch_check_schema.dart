import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final response = await client.from('fcm_tokens').select().limit(1);
    print('Response: $response');
    if ((response as List).isNotEmpty) {
      print('Columns in fcm_tokens table:');
      print((response[0]).keys.join(', '));
    }
  } catch (e) {
    print('Error: $e');
  }

  // Check unique constraints/indexes on fcm_tokens if possible, or just try an upsert
  try {
    await client.from('fcm_tokens').upsert({
        'user_id': '00000000-0000-0000-0000-000000000000',
        'token': 'test_token',
        'platform': 'test',
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,token');
    print('Upsert 1 (user_id,token) succeeded!');
  } catch (e) {
    print('Upsert 1 failed: $e');
  }
  
  try {
    await client.from('fcm_tokens').upsert({
        'user_id': '00000000-0000-0000-0000-000000000000',
        'token': 'test_token',
        'platform': 'test',
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
    print('Upsert 2 (token) succeeded!');
  } catch (e) {
    print('Upsert 2 failed: $e');
  }
  
  client.dispose();
  exit(0);
}
