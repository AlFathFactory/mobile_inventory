import 'package:supabase_flutter/supabase_flutter.dart';

import 'inventory_remote_data_source.dart';

class SupabaseInventoryService implements InventoryRemoteDataSource {
  const SupabaseInventoryService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<String>> fetchCategories() async {
    final categories = <String>[];
    String? last;
    for (var index = 0; index < 100; index++) {
      final rows = await _client
          .from(InventoryRemoteQuery.viewName)
          .select('category_name')
          .gt('category_name', last ?? '')
          .order('category_name')
          .limit(1);
      if (rows.isEmpty) break;
      final name = (rows.single as Map)['category_name'];
      if (name is! String || name.isEmpty) break;
      categories.add(name);
      last = name;
    }
    return categories;
  }

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
