import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../inventory/model/inventory_item.dart';
import 'alerts_remote_data_source.dart';

class SupabaseAlertsService implements AlertsRemoteDataSource {
  const SupabaseAlertsService(this._client);

  final SupabaseClient _client;

  @override
  Future<int> countAlerts(
    AlertsRemoteQuery query, {
    required StockStatus status,
  }) async {
    dynamic builder = _client.from(AlertsRemoteQuery.viewName).count();
    builder = _applyBaseFilters(builder, query);
    return await builder.eq('status', status.alertViewValue) as int;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAlerts(
    AlertsRemoteQuery query, {
    required StockStatus status,
    required int offset,
    required int limit,
  }) async {
    dynamic builder = _client
        .from(AlertsRemoteQuery.viewName)
        .select(AlertsRemoteQuery.selectedColumns.join(','));
    builder = _applyBaseFilters(builder, query);
    builder = builder.eq('status', status.alertViewValue);
    for (final order in AlertsRemoteQuery.orderColumns) {
      builder = builder.order(
        order.column,
        ascending: order.ascending,
        nullsFirst: false,
      );
    }

    final response = await builder.range(offset, offset + limit - 1);
    return (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  dynamic _applyBaseFilters(dynamic builder, AlertsRemoteQuery query) {
    if (query.search.isNotEmpty) {
      final pattern = '*${query.search}*';
      builder = builder.or(
        AlertsRemoteQuery.searchColumns
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
    return builder;
  }
}
