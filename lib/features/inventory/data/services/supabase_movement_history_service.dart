import 'package:supabase_flutter/supabase_flutter.dart';

import 'movement_history_remote_data_source.dart';

class SupabaseMovementHistoryService
    implements MovementHistoryRemoteDataSource {
  const SupabaseMovementHistoryService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchMovements(
    MovementHistoryRemoteQuery query,
  ) async {
    dynamic builder = _client
        .from(MovementHistoryRemoteQuery.viewName)
        .select(MovementHistoryRemoteQuery.selectedColumns.join(','))
        .eq('table_name', query.identity.tableName)
        .eq('item_id', query.identity.itemId);

    for (final order in MovementHistoryRemoteQuery.orderColumns) {
      builder = builder.order(
        order.column,
        ascending: order.ascending,
        nullsFirst: false,
      );
    }

    final response = await builder.range(query.offset, query.rangeEnd);
    return (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}
