import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class SupabaseConfigurationException implements Exception {
  const SupabaseConfigurationException();
}

class SupabaseConnectionException implements Exception {
  const SupabaseConnectionException();
}

abstract final class SupabaseBootstrap {
  /// Initializes the official client only when build-time values are present.
  /// Returning the client supports constructor injection into future Supabase
  /// repositories; feature code should not read the global singleton directly.
  static Future<SupabaseClient?> initialize({
    SupabaseConfig config = SupabaseConfig.environment,
  }) async {
    if (!config.isConfigured) return null;

    final supabase = await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
    return supabase.client;
  }
}
