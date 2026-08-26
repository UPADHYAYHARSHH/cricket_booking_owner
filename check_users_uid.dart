import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://qcybnzopffyzmpiaxwbc.supabase.co';
  final supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final specificUser = await client.from('users').select('id, user_id, name, photo_url').eq('user_id', 'fESOB7wWXOUvHhi7fUiY7wBKtsC2').maybeSingle();
    print('Specific user query by user_id: $specificUser');
    
    // Also try without eq
    final allUsers = await client.from('users').select('id, user_id, name, photo_url').limit(5);
    print('All users: $allUsers');

  } catch (e) {
    print('Error: $e');
  }

  client.dispose();
  exit(0);
}
