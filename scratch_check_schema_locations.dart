import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final response = await client.from('locations').select().limit(1);
    if ((response as List).isNotEmpty) {
      print('Columns in locations table:');
      print((response[0] as Map).keys.join(', '));
      print(jsonEncode(response[0]));
    } else {
      print('Locations table is empty, cannot infer schema easily.');
    }
  } catch (e) {
    print('Error: $e');
  }

  // Also check if location_images or location_documents tables exist
  try {
    final response = await client.from('location_images').select().limit(1);
    print('location_images exists.');
  } catch(e) {
    print('location_images error: $e');
  }

  try {
    final response = await client.from('location_documents').select().limit(1);
    print('location_documents exists.');
  } catch(e) {
    print('location_documents error: $e');
  }

  client.dispose();
  exit(0);
}
