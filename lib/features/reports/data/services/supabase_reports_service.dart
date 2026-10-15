import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'reports_remote_data_source.dart';

class SupabaseReportsService implements ReportsRemoteDataSource {
  SupabaseReportsService(this._client);

  final SupabaseClient _client;
  String? _cachedFilterKey;
  int? _cachedTotal;
  Map<String, dynamic>? _cachedAggregate;

  @override
  Future<ReportsRemoteResponse> fetchReports(ReportsRemoteQuery query) async {
    final filterKey = jsonEncode(query.rpcParams);
    if (query.offset > 0 &&
        filterKey == _cachedFilterKey &&
        _cachedTotal != null &&
        _cachedAggregate != null) {
      return ReportsRemoteResponse(
        rows: await _fetchRows(query),
        totalMovements: _cachedTotal!,
        aggregated: _cachedAggregate!,
      );
    }
    final results = await Future.wait<Object>([
      _fetchRows(query),
      _countRows(query),
      _fetchAggregate(query),
    ]);
    final response = ReportsRemoteResponse(
      rows: results[0] as List<Map<String, dynamic>>,
      totalMovements: results[1] as int,
      aggregated: results[2] as Map<String, dynamic>,
    );
    _cachedFilterKey = filterKey;
    _cachedTotal = response.totalMovements;
    _cachedAggregate = response.aggregated;
    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchRows(
    ReportsRemoteQuery query,
  ) async {
    dynamic builder = _client
        .from(ReportsRemoteQuery.viewName)
        .select(ReportsRemoteQuery.columns.join(','));
    builder = _filters(builder, query);
    final response = await builder
        .order('operation_date', ascending: false)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(query.offset, query.rangeEnd);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<int> _countRows(ReportsRemoteQuery query) async {
    dynamic builder = _client.from(ReportsRemoteQuery.viewName).count();
    builder = _filters(builder, query);
    return await builder as int;
  }

  Future<Map<String, dynamic>> _fetchAggregate(ReportsRemoteQuery query) async {
    if (query.operationType == 'return' || query.operationType == 'adjust') {
      return {
        'summary': {
          'issue_operations_count': 0,
          'addition_operations_count': 0,
        },
      };
    }
    // The RPC normalizes Arabic search while the view uses ILIKE. Count-only
    // reads keep these metrics aligned with the visible timeline search.
    if (query.safeSearch.isNotEmpty) {
      final counts = await Future.wait([
        _countRows(query.withOperationType('issue')),
        _countRows(query.withOperationType('add')),
      ]);
      return {
        'summary': {
          'issue_operations_count': counts[0],
          'addition_operations_count': counts[1],
        },
      };
    }
    final response = await _client.rpc(
      ReportsRemoteQuery.rpcName,
      params: query.rpcParams,
    );
    if (response is! Map) {
      throw const FormatException('Invalid aggregate reports response.');
    }
    return Map<String, dynamic>.from(response);
  }

  dynamic _filters(dynamic builder, ReportsRemoteQuery query) {
    if (query.fromDate != null) {
      builder = builder.gte('operation_date', query.fromDate!);
    }
    if (query.toDate != null) {
      builder = builder.lte('operation_date', query.toDate!);
    }
    if (query.operationType != null) {
      builder = builder.eq('operation_type', query.operationType!);
    }
    if (query.category != null) {
      builder = builder.eq('category_name', query.category!);
    }
    if (query.project != null) {
      builder = builder.eq('project_name', query.project!);
    }
    if (query.safeSearch.isNotEmpty) {
      final pattern = '*${query.safeSearch}*';
      builder = builder.or(
        ReportsRemoteQuery.searchColumns
            .map((column) => '$column.ilike.$pattern')
            .join(','),
      );
    }
    return builder;
  }

  @override
  Future<ReportsFilterOptions> fetchFilterOptions() async {
    final projectRows = await _client
        .from('projects')
        .select('name')
        .order('name');
    final projects =
        (projectRows as List)
            .map((row) => (row as Map)['name'])
            .whereType<String>()
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // PostgREST does not expose SELECT DISTINCT. Advance one unique value at
    // a time so no movement history is downloaded just to fill this menu.
    final categories = <String>[];
    String? last;
    for (var index = 0; index < 100; index++) {
      dynamic builder = _client
          .from(ReportsRemoteQuery.viewName)
          .select('category_name')
          .gt('category_name', last ?? '');
      final rows = await builder.order('category_name').limit(1) as List;
      if (rows.isEmpty) break;
      final name = (rows.single as Map)['category_name'];
      if (name is! String || name.isEmpty) break;
      categories.add(name);
      last = name;
    }
    return ReportsFilterOptions(categories: categories, projects: projects);
  }
}
