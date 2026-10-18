import 'package:supabase_flutter/supabase_flutter.dart';

import 'inventory_category_names.dart';

/// Lightweight shared source for category filter options.
abstract interface class InventoryCategoryCatalog {
  Future<List<String>> fetchCategories();
}

/// Reads active dynamic categories without scanning inventory or movement rows.
class SupabaseInventoryCategoryCatalog implements InventoryCategoryCatalog {
  const SupabaseInventoryCategoryCatalog(this._client);

  final SupabaseClient _client;

  @override
  Future<List<String>> fetchCategories() async {
    final rows = await _client
        .from('categories')
        .select('name')
        .eq('is_archived', false)
        .order('name', ascending: true);
    return InventoryCategoryNames.mergeDynamicCategories(
      (rows as List).map((row) => (row as Map)['name']),
    );
  }
}
