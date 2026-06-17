import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://qcybnzopffyzmpiaxwbc.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjeWJuem9wZmZ5em1waWF4d2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMDYyNzMsImV4cCI6MjA4OTY4MjI3M30.cRnvZzQhbwI26PhRkdjnptVa5yiWo6oBIGZlZU7JEgg');

  try {
    final users = await supabase.from('users').select().limit(1);
    print("Users schema: \${users}");
  } catch (e) {
    print("Error users: $e");
  }
}
