import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/unavailable_repositories.dart';

import '../services/supabase_reports_service.dart';
import 'reports_repository.dart';
import 'supabase_reports_repository.dart';

abstract final class ReportsRepositoryFactory {
  static ReportsRepository create(SupabaseClient? client) {
    if (client == null) return const UnavailableReportsRepository();
    return SupabaseReportsRepository(SupabaseReportsService(client));
  }
}
