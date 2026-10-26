import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/unavailable_repositories.dart';

import '../services/supabase_inventory_service.dart';
import '../services/inventory_remote_data_source.dart';
import 'inventory_repository.dart';
import 'supabase_inventory_repository.dart';

abstract final class InventoryRepositoryFactory {
  static InventoryRepository create(
    SupabaseClient? client, {
    InventoryRemoteDataSource? remoteDataSource,
  }) {
    final remote =
        remoteDataSource ??
        (client == null ? null : SupabaseInventoryService(client));
    return remote == null
        ? const UnavailableInventoryRepository()
        : SupabaseInventoryRepository(remote);
  }
}
