import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _initialized = false;

  static Future<void> initializeFromEnvironment() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    await initialize(url: url, anonKey: anonKey);
  }

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) {
      return;
    }

    if (url.trim().isEmpty || anonKey.trim().isEmpty) {
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _initialized = true;
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase ainda não foi inicializado. Configure SUPABASE_URL e SUPABASE_ANON_KEY.',
      );
    }

    return Supabase.instance.client;
  }

  static String? get currentUserId =>
      _initialized ? Supabase.instance.client.auth.currentUser?.id : null;

  static String? get currentUserEmail =>
      _initialized ? Supabase.instance.client.auth.currentUser?.email : null;

  static bool get isConfigured => _initialized;
}
