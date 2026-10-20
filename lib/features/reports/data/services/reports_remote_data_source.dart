import 'package:flutter/foundation.dart';

import '../../../../core/utils/search_normalizer.dart';

import '../../../inventory/model/inventory_movement.dart';
import '../models/reports_query.dart';

@immutable
class ReportsRemoteQuery {
  const ReportsRemoteQuery({
    required this.offset,
    required this.pageSize,
    required this.search,
    required this.operationType,
    required this.category,
    required this.project,
    required this.fromDate,
    required this.toDate,
  });

  factory ReportsRemoteQuery.fromQuery(ReportsQuery query) {
    final offset = query.page.cursor == null
        ? 0
        : int.tryParse(query.page.cursor!);
    if (offset == null ||
        offset < 0 ||
        query.types.length > 1 ||
        query.categories.length > 1 ||
        query.projects.length > 1) {
      throw const FormatException('Unsupported reports query or cursor.');
    }
    return ReportsRemoteQuery(
      offset: offset,
      pageSize: query.page.limit,
      search: normalizeSearchTerm(query.search),
      operationType: query.types.isEmpty
          ? null
          : switch (query.types.single) {
              MovementType.addition => 'add',
              MovementType.issue => 'issue',
              MovementType.returned => 'return',
              MovementType.adjustment => 'adjust',
            },
      category: query.categories.isEmpty ? null : query.categories.single,
      project: query.projects.isEmpty ? null : query.projects.single,
      fromDate: _date(query.startDate),
      toDate: _date(query.endDate),
    );
  }

  static const rpcName = 'get_aggregated_inventory_report_rpc';
  static const viewName = 'inventory_item_movements_view';
  static const columns = <String>[
    'id',
    'table_name',
    'item_id',
    'item_name',
    'item_label',
    'category_name',
    'category_label',
    'project_name',
    'project',
    'operation_type',
    'quantity',
    'operation_date',
    'created_at',
    'previous_balance',
    'new_balance',
    'supplier_name',
    'issued_to',
    'received_by',
    'purchase_order_number',
    'item_code',
    'notes',
    'code_number',
    'internal_code',
    'din',
  ];
  static const searchColumns = <String>[
    'item_name',
    'item_label',
    'category_name',
    'category_label',
    'project_name',
    'project',
    'item_code',
    'code_number',
    'internal_code',
    'din',
  ];

  final int offset;
  final int pageSize;
  final String search;
  final String? operationType;
  final String? category;
  final String? project;
  final String? fromDate;
  final String? toDate;

  int get rangeEnd => offset + pageSize;

  ReportsRemoteQuery withOperationType(String type) => ReportsRemoteQuery(
    offset: offset,
    pageSize: pageSize,
    search: search,
    operationType: type,
    category: category,
    project: project,
    fromDate: fromDate,
    toDate: toDate,
  );

  /// Actual deployed signature: date, date, text, text, text, text,
  /// integer page, integer page size. One row is enough for global summary.
  Map<String, dynamic> get rpcParams => {
    'p_from_date': fromDate,
    'p_to_date': toDate,
    'p_category_name': category,
    'p_project_name': project,
    'p_search': search.isEmpty ? null : search,
    'p_operation_type': operationType,
    'p_page': 1,
    'p_page_size': 1,
  };

  String get safeSearch => search
      .replaceAll(RegExp(r'[,().:*]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String? _date(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-'
            '${value.month.toString().padLeft(2, '0')}-'
            '${value.day.toString().padLeft(2, '0')}';
}

@immutable
class ReportsRemoteResponse {
  const ReportsRemoteResponse({
    required this.rows,
    required this.totalMovements,
    required this.aggregated,
  });

  final List<Map<String, dynamic>> rows;
  final int totalMovements;
  final Map<String, dynamic> aggregated;
}

@immutable
class ReportsFilterOptions {
  const ReportsFilterOptions({
    required this.categories,
    required this.projects,
  });

  final List<String> categories;
  final List<String> projects;
}

abstract interface class ReportsRemoteDataSource {
  Future<ReportsRemoteResponse> fetchReports(ReportsRemoteQuery query);
  Future<ReportsFilterOptions> fetchFilterOptions();
}
