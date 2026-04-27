import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Shortcut ke Supabase client — pakai dari mana saja
  static SupabaseClient get db      => Supabase.instance.client;
  static GoTrueClient   get auth    => Supabase.instance.client.auth;
  static SupabaseStorageClient get storage => Supabase.instance.client.storage;
}