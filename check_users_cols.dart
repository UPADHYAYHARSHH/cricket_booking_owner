import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    // Try to get a user via auth API if it's not in public schema, 
    // or try querying public.users but get columns from error
    final response = await client.from('users').select('name, image_url, full_name, avatar_url, profile_image').limit(1);
    print('Users response: $response');
  } catch (e) {
    print('Error: $e');
  }

  client.dispose();
  exit(0);
}
