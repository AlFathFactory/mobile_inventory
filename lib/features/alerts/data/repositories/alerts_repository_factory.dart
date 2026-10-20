import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/unavailable_repositories.dart';

import '../services/supabase_alerts_service.dart';
import 'alerts_repository.dart';
import 'supabase_alerts_repository.dart';

abstract final class AlertsRepositoryFactory {
  static AlertsRepository create(SupabaseClient? client) {
    if (client == null) return const UnavailableAlertsRepository();
    return SupabaseAlertsRepository(SupabaseAlertsService(client));
  }
}
