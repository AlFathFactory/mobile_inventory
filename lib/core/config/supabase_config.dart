import 'package:flutter/foundation.dart';

@immutable
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  static const environment = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  final String url;
  final String publishableKey;

  bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
