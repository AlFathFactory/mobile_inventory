import 'package:supabase_flutter/supabase_flutter.dart';

import 'inventory_remote_data_source.dart';

class SupabaseInventoryService implements InventoryRemoteDataSource {
  const SupabaseInventoryService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async {
    dynamic builder = _client
        .from(InventoryRemoteQuery.viewName)
        .select(InventoryRemoteQuery.selectedColumns.join(','));

    if (query.search.isNotEmpty) {
      final pattern = '*${query.search}*';
      builder = builder.or(
        InventoryRemoteQuery.searchColumns
            .map((column) => '$column.ilike.$pattern')
            .join(','),
      );
    }
    if (query.categories.isNotEmpty) {
      builder = builder.inFilter('category_name', query.categories);
    }
    if (query.projects.isNotEmpty) {
      builder = builder.inFilter('project_name', query.projects);
    }
    if (query.statuses.isNotEmpty) {
      builder = builder.inFilter('status', query.statuses);
    }

    for (final order in InventoryRemoteQuery.orderColumns) {
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
