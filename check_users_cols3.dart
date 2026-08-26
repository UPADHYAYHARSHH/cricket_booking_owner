import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  final possibleColumns = [
    'name, profile_image',
    'full_name, profile_image',
    'name, avatar_url',
    'full_name, avatar_url',
    'name, image',
    'full_name, image',
    'first_name, avatar_url',
    'full_name',
    'name'
  ];

  for (final cols in possibleColumns) {
    try {
      final response = await client.from('users').select(cols).limit(1);
      print('Success with cols: $cols -> $response');
      break;
    } catch (e) {
      print('Failed for $cols');
    }
  }

  client.dispose();
  exit(0);
}
