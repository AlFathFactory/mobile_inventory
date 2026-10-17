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
}
