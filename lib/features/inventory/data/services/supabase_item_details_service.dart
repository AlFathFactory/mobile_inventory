import 'package:supabase_flutter/supabase_flutter.dart';

import 'item_details_remote_data_source.dart';

class SupabaseItemDetailsService implements ItemDetailsRemoteDataSource {
  const SupabaseItemDetailsService(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchItem(ItemDetailsRemoteQuery query) async {
    final response = await _client
        .from(ItemDetailsRemoteQuery.viewName)
        .select(ItemDetailsRemoteQuery.selectedColumns.join(','))
        .eq('table_name', query.tableName)
        .eq('item_id', query.itemId)
        .limit(1);

    final rows = response as List<dynamic>;
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.single as Map);
  }

  @override
  Future<String?> fetchPaintProductionDate(String itemId) async {
    final response = await _client
        .from('paints')
        .select('id,production_date')
        .eq('id', itemId)
        .limit(1);

    final rows = response as List<dynamic>;
    if (rows.isEmpty) return null;
    final row = Map<String, dynamic>.from(rows.single as Map);
    final value = row['production_date'];
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is num) return value.toString();
    return null;
  }
}
