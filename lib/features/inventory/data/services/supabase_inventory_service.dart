import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/inventory_category_catalog.dart';
import '../../../../core/utils/search_normalizer.dart';
import 'inventory_remote_data_source.dart';

class SupabaseInventoryService implements InventoryRemoteDataSource {
  SupabaseInventoryService(
    this._client, {
    InventoryCategoryCatalog? categoryCatalog,
  }) : _categoryCatalog =
           categoryCatalog ?? SupabaseInventoryCategoryCatalog(_client);

  final SupabaseClient _client;
  final InventoryCategoryCatalog _categoryCatalog;

  @override
  Future<List<String>> fetchCategories() async {
    return _categoryCatalog.fetchCategories();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async {
    dynamic builder = _client
        .from(InventoryRemoteQuery.viewName)
        .select(InventoryRemoteQuery.selectedColumns.join(','));

    if (query.search.isNotEmpty) {
      final pattern = searchPatternForNormalizedTerm(query.search);
      builder = builder.or(
        InventoryRemoteQuery.searchColumns
            .map((column) => '$column.imatch.$pattern')
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
