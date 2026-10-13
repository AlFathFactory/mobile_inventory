import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_alerts_service.dart';
import 'alerts_repository.dart';
import 'preview_alerts_repository.dart';
import 'supabase_alerts_repository.dart';

abstract final class AlertsRepositoryFactory {
  static AlertsRepository create(SupabaseClient? client) {
    if (client == null) return const PreviewAlertsRepository();
    return SupabaseAlertsRepository(SupabaseAlertsService(client));
  }
}
