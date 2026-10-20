import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/inventory_local_data_source.dart';
import '../services/supabase_inventory_service.dart';
import '../services/inventory_sync_coordinator.dart';
import 'cached_inventory_repository.dart';
import 'inventory_repository.dart';
import 'preview_inventory_repository.dart';
import 'supabase_inventory_repository.dart';

abstract final class InventoryRepositoryFactory {
  static InventoryRepository create(
    SupabaseClient? client, {
    InventoryLocalDataSource? localDataSource,
  }) {
    if (client == null) return const PreviewInventoryRepository();
    final remote = SupabaseInventoryService(client);
    final local = localDataSource;
    if (local == null) return SupabaseInventoryRepository(remote);
    return CachedInventoryRepository(
      local: local,
      syncCoordinator: InventorySyncCoordinator(local: local, remote: remote),
    );
  }
}
