/// Shared backend identifiers for the Dashboard live read path.
abstract final class DashboardRemote {
  /// Read-only aggregate RPC. Must perform no database mutation.
  static const summaryRpc = 'get_inventory_dashboard_summary_rpc';

  static const summaryViewName = 'inventory_category_items_summary_view';
  static const movementsViewName = 'inventory_item_movements_view';

  /// Only the fields required to render an alert preview card.
  static const attentionColumns = <String>[
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

  /// Only the fields required to render a recent-activity row.
  static const movementColumns = <String>[
    'id',
    'table_name',
    'category_name',
    'category_label',
    'item_id',
    'item_name',
    'item_label',
    'project_name',
    'project',
    'operation_type',
    'quantity',
    'operation_date',
    'previous_balance',
    'new_balance',
    'supplier_name',
    'issued_to',
    'received_by',
    'purchase_order_number',
    'item_code',
    'notes',
    'created_at',
    'code_number',
    'internal_code',
  ];

  static const outOfStockStatus = 'منتهي';
  static const lowStatus = 'قليل';
}

/// Raw read-only Dashboard payload. Mapping into domain models stays in
/// the repository so widgets and controllers never touch backend shapes.
abstract interface class DashboardRemoteDataSource {
  Future<Map<String, dynamic>> fetchSummary();

  Future<List<Map<String, dynamic>>> fetchAttentionItems({required int limit});

  Future<List<Map<String, dynamic>>> fetchRecentMovements({required int limit});
}
