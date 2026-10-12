import 'package:flutter/foundation.dart';

import '../../model/inventory_item.dart';
import '../models/inventory_query.dart';

@immutable
class InventoryRemoteQuery {
  const InventoryRemoteQuery({
    required this.offset,
    required this.pageSize,
    required this.fetchLimit,
    required this.search,
    required this.categories,
    required this.projects,
    required this.statuses,
  });

  factory InventoryRemoteQuery.fromInventoryQuery(InventoryQuery query) {
    final cursor = query.page.cursor;
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const FormatException('Invalid inventory page cursor.');
    }

    return InventoryRemoteQuery(
      offset: offset,
      pageSize: query.page.limit,
      // Fetch one look-ahead row so pagination does not need an expensive
      // exact count across the unified view.
      fetchLimit: query.page.limit + 1,
      search: _safeSearch(query.search),
      categories: _stableValues(query.categories),
      projects: _stableValues(query.projects),
      statuses: _stableValues(
        query.statuses.map((status) => status.summaryViewValue),
      ),
    );
  }

  static const viewName = 'inventory_category_items_summary_view';

  static const selectedColumns = <String>[
    'table_name',
    'category_name',
    'item_id',
    'item_key',
    'project_name',
    'item_name',
    'stock_balance',
    'min_quantity',
    'status',
    'supplier_name',
    'expire_date',
    'notes',
    'updated_at',
    'created_at',
    'code_number',
    'internal_code',
  ];

  static const orderColumns = <InventoryRemoteOrder>[
    InventoryRemoteOrder('updated_at', ascending: false),
    InventoryRemoteOrder('table_name'),
    InventoryRemoteOrder('item_id'),
  ];

  static const searchColumns = <String>[
    'item_name',
    'internal_code',
    'code_number',
    'project_name',
    'supplier_name',
  ];

  final int offset;
  final int pageSize;
  final int fetchLimit;
  final String search;
  final List<String> categories;
  final List<String> projects;
  final List<String> statuses;

  int get rangeEnd => offset + fetchLimit - 1;

  static List<String> _stableValues(Iterable<String> values) {
    final result = values.where((value) => value.isNotEmpty).toSet().toList()
      ..sort();
    return List.unmodifiable(result);
  }

  static String _safeSearch(String value) {
    // `or()` uses PostgREST filter syntax, so remove its structural tokens
    // instead of allowing user input to become a filter expression.
    return value
        .trim()
        .replaceAll(RegExp(r'[,().:*]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

@immutable
class InventoryRemoteOrder {
  const InventoryRemoteOrder(this.column, {this.ascending = true});

  final String column;
  final bool ascending;
}

extension StockStatusSummaryViewValue on StockStatus {
  String get summaryViewValue => switch (this) {
    StockStatus.safe => 'آمن',
    StockStatus.low => 'قليل',
    StockStatus.outOfStock => 'منتهي',
  };
}

abstract interface class InventoryRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchItems(InventoryRemoteQuery query);
}
