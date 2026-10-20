import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/repositories/unavailable_repositories.dart';

import '../local/inventory_local_data_source.dart';
import '../services/supabase_inventory_service.dart';
import '../services/inventory_sync_coordinator.dart';
import '../services/inventory_remote_data_source.dart';
import 'cached_inventory_repository.dart';
import 'inventory_repository.dart';
import 'supabase_inventory_repository.dart';

abstract final class InventoryRepositoryFactory {
  static InventoryRepository create(
    SupabaseClient? client, {
    InventoryLocalDataSource? localDataSource,
    InventoryRemoteDataSource? remoteDataSource,
  }) {
    final remote =
        remoteDataSource ??
        (client == null ? null : SupabaseInventoryService(client));
    final local = localDataSource;
    if (local == null) {
      return remote == null
          ? const UnavailableInventoryRepository()
          : SupabaseInventoryRepository(remote);
    }
    return CachedInventoryRepository(
      local: local,
      syncCoordinator: InventorySyncCoordinator(
        local: local,
        remote: remote ?? const UnavailableInventoryRemoteDataSource(),
      ),
    );
  }
}

class UnavailableInventoryRemoteDataSource
    implements InventoryRemoteDataSource {
  const UnavailableInventoryRemoteDataSource();

  @override
  Future<List<String>> fetchCategories() =>
      Future.error(StateError('Supabase is unavailable'));

  @override
  Future<List<Map<String, dynamic>>> fetchItems(InventoryRemoteQuery query) =>
      Future.error(StateError('Supabase is unavailable'));
}
