import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    // Try to find if user_id or uid is the primary key instead of id
    final possibleIdCols = ['id', 'uid', 'user_id', 'firebase_uid'];
    
    for (final col in possibleIdCols) {
      try {
        final res = await client.from('users').select('$col, name, photo_url').limit(1);
        print('Success with col $col: $res');
      } catch (e) {
        print('Failed with col $col');
      }
    }
    
    // Also try to query that specific user
    final specificUser = await client.from('users').select('id, name').eq('id', 'fESOB7wWXOUvHhi7fUiY7wBKtsC2').maybeSingle();
    print('Specific user query by id: $specificUser');

  } catch (e) {
    print('Error: $e');
  }

  client.dispose();
  exit(0);
}
