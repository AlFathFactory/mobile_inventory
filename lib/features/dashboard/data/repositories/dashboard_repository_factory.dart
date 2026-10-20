import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/unavailable_repositories.dart';

import '../services/supabase_dashboard_service.dart';
import 'dashboard_repository.dart';
import 'supabase_dashboard_repository.dart';

abstract final class DashboardRepositoryFactory {
  static DashboardRepository create(SupabaseClient? client) {
    if (client == null) return const UnavailableDashboardRepository();
    return SupabaseDashboardRepository(SupabaseDashboardService(client));
  }
}
