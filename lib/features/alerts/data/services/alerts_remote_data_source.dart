import 'package:flutter/foundation.dart';

import '../../../inventory/model/inventory_item.dart';
import '../models/alerts_query.dart';

@immutable
class AlertsRemoteQuery {
  const AlertsRemoteQuery({
    required this.offset,
    required this.pageSize,
    required this.fetchLimit,
    required this.search,
    required this.categories,
    required this.projects,
    required this.statuses,
  });

  factory AlertsRemoteQuery.fromAlertsQuery(AlertsQuery query) {
    final cursor = query.page.cursor;
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const FormatException('Invalid alerts page cursor.');
    }

    final statuses = query.statuses.isEmpty
        ? alertStatuses
        : alertStatuses.where(query.statuses.contains).toList(growable: false);

    return AlertsRemoteQuery(
      offset: offset,
      pageSize: query.page.limit,
      fetchLimit: query.page.limit + 1,
      search: _safeSearch(query.search),
      categories: _stableValues(query.categories),
      projects: _stableValues(query.projects),
      statuses: statuses,
    );
  }

  static const viewName = 'inventory_category_items_summary_view';

  /// Only the fields required to render an alert and open its detail route.
  static const selectedColumns = <String>[
    'table_name',
    'item_id',
    'item_key',
    'category_name',
    'project_name',
    'item_name',
    'stock_balance',
    'min_quantity',
    'status',
    'code_number',
    'internal_code',
  ];

  static const searchColumns = <String>[
    'item_name',
    'internal_code',
    'code_number',
    'project_name',
  ];

  static const orderColumns = <AlertsRemoteOrder>[
    AlertsRemoteOrder('updated_at', ascending: false),
    AlertsRemoteOrder('table_name'),
    AlertsRemoteOrder('item_id'),
  ];

  /// Severity order is explicit and independent of database collation.
  static const alertStatuses = <StockStatus>[
    StockStatus.outOfStock,
    StockStatus.low,
  ];

  final int offset;
  final int pageSize;
  final int fetchLimit;
  final String search;
  final List<String> categories;
  final List<String> projects;
  final List<StockStatus> statuses;

  static List<String> _stableValues(Iterable<String> values) {
    final result = values.where((value) => value.isNotEmpty).toSet().toList()
      ..sort();
    return List.unmodifiable(result);
  }

  static String _safeSearch(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[,().:*]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

@immutable
class AlertsRemoteOrder {
  const AlertsRemoteOrder(this.column, {this.ascending = true});

  final String column;
  final bool ascending;
}

extension AlertStockStatusViewValue on StockStatus {
  String get alertViewValue => switch (this) {
    StockStatus.safe => 'آمن',
    StockStatus.low => 'قليل',
    StockStatus.outOfStock => 'منتهي',
  };
}

abstract interface class AlertsRemoteDataSource {
  Future<int> countAlerts(
    AlertsRemoteQuery query, {
    required StockStatus status,
  });

  Future<List<Map<String, dynamic>>> fetchAlerts(
    AlertsRemoteQuery query, {
    required StockStatus status,
    required int offset,
    required int limit,
  });
}
