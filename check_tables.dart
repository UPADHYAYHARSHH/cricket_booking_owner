import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final response = await client.rpc('get_tables');
    print('RPC tables: $response');
  } catch (e) {
    print('RPC failed: $e');
  }
  
  // Try querying a few common table names
  final tables = ['profiles', 'user_profiles', 'customers', 'user_details', 'owner_details'];
  for (var table in tables) {
    try {
      final res = await client.from(table).select().limit(1);
      print('Table $table exists, rows: ${res.length}');
    } catch (e) {
      print('Table $table does not exist');
    }
  }

  client.dispose();
  exit(0);
}
