import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_URL.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY';
}

final supabase = Supabase.instance.client;
