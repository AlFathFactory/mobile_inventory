import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/inventory/data/services/inventory_remote_data_source.dart';
import '../../../features/inventory/data/services/supabase_inventory_service.dart';
import 'supabase_bootstrap.dart';

/// Delays inventory requests until the startup client is ready.
class ConnectingInventorySource implements InventoryRemoteDataSource {
  const ConnectingInventorySource(this._connect, this._connectionError);

  final Future<SupabaseClient?> Function() _connect;
  final Object? Function() _connectionError;

  Future<SupabaseInventoryService> _service() async {
    final client = await _connect();
    if (client == null) {
      throw _connectionError() ?? const SupabaseConnectionException();
    }
    return SupabaseInventoryService(client);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async => (await _service()).fetchItems(query);

  @override
  Future<List<String>> fetchCategories() async =>
      (await _service()).fetchCategories();
}
