import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_reports_service.dart';
import 'preview_reports_repository.dart';
import 'reports_repository.dart';
import 'supabase_reports_repository.dart';

abstract final class ReportsRepositoryFactory {
  static ReportsRepository create(SupabaseClient? client) {
    if (client == null) return const PreviewReportsRepository();
    return SupabaseReportsRepository(SupabaseReportsService(client));
  }
}
