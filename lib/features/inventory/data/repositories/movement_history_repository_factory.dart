import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/unavailable_repositories.dart';

import '../services/supabase_movement_history_service.dart';
import 'movement_history_repository.dart';
import 'supabase_movement_history_repository.dart';

abstract final class MovementHistoryRepositoryFactory {
  static MovementHistoryRepository create(SupabaseClient? client) {
    if (client == null) return const UnavailableMovementHistoryRepository();
    return SupabaseMovementHistoryRepository(
      SupabaseMovementHistoryService(client),
    );
  }
}
