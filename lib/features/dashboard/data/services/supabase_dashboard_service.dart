import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_remote_data_source.dart';

class SupabaseDashboardService implements DashboardRemoteDataSource {
  const SupabaseDashboardService(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> fetchSummary() async {
    final response = await _client.rpc(DashboardRemote.summaryRpc);
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return const <String, dynamic>{};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttentionItems({
    required int limit,
  }) async {
    if (limit <= 0) return const [];
    // Severity-first without downloading safe rows: out-of-stock fills the
    // preview first, low-stock completes it. Same segment strategy and
    // ordering as the live Alerts implementation.
    final outOfStock = await _fetchAttentionSegment(
      status: DashboardRemote.outOfStockStatus,
      offset: 0,
      limit: limit,
    );
    if (outOfStock.length >= limit) return outOfStock;
    final lowStock = await _fetchAttentionSegment(
      status: DashboardRemote.lowStatus,
      offset: 0,
      limit: limit - outOfStock.length,
    );
    return [...outOfStock, ...lowStock];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecentMovements({
    required int limit,
  }) async {
    if (limit <= 0) return const [];
    dynamic builder = _client
        .from(DashboardRemote.movementsViewName)
        .select(DashboardRemote.movementColumns.join(','))
        .order('operation_date', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false, nullsFirst: false)
        .order('id', ascending: false, nullsFirst: false);

    final response = await builder.range(0, limit - 1);
    return (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchAttentionSegment({
    required String status,
    required int offset,
    required int limit,
  }) async {
    dynamic builder = _client
        .from(DashboardRemote.summaryViewName)
        .select(DashboardRemote.attentionColumns.join(','))
        .eq('status', status)
        .order('updated_at', ascending: false, nullsFirst: false)
        .order('table_name', nullsFirst: false)
        .order('item_id', nullsFirst: false);

    final response = await builder.range(offset, offset + limit - 1);
    return (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}
