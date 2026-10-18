/// Converts legacy inventory table keys to the `category_name` values exposed
/// by `inventory_category_items_summary_view`.
abstract final class InventoryCategoryNames {
  static const legacyDisplayNames = <String, String>{
    'consumables': 'مستهلكات',
    'paints': 'الدهانات',
    'screws': 'مسامير',
    'stock_screws': 'مسامير استوك',
    'raw_materials': 'خامات',
  };

  /// Returns a view-compatible Arabic category for a legacy key, without
  /// altering dynamic category names or values already supplied by the view.
  static String displayNameFor(String categoryName) =>
      legacyDisplayNames[categoryName] ?? categoryName;

  /// Produces the single category order used by Dashboard, Inventory, and
  /// Reports: legacy view-compatible names first, then dynamic names.
  static List<String> mergeDynamicCategories(Iterable<Object?> dynamicNames) {
    final categories = <String>[...legacyDisplayNames.values];
    final seen = categories.toSet();
    final dynamic = <String>[];
    for (final value in dynamicNames) {
      if (value is! String || value.trim().isEmpty || !seen.add(value)) {
        continue;
      }
      dynamic.add(value);
    }
    dynamic.sort();
    return List.unmodifiable([...categories, ...dynamic]);
  }
}
