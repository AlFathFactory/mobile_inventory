import 'package:flutter/foundation.dart';

import '../models/live_item_identity.dart';
import '../models/movement_history_query.dart';

@immutable
class MovementHistoryRemoteQuery {
  const MovementHistoryRemoteQuery({
    required this.identity,
    required this.offset,
    required this.pageSize,
    required this.fetchLimit,
  });

  factory MovementHistoryRemoteQuery.fromQuery(
    MovementHistoryQuery query,
    LiveItemIdentity identity,
  ) {
    final cursor = query.page.cursor;
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const FormatException('Invalid movement-history page cursor.');
    }

    return MovementHistoryRemoteQuery(
      identity: identity,
      offset: offset,
      pageSize: query.page.limit,
      fetchLimit: query.page.limit + 1,
    );
  }

  static const viewName = 'inventory_item_movements_view';

  static const selectedColumns = <String>[
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

  static const orderColumns = <MovementHistoryRemoteOrder>[
    MovementHistoryRemoteOrder('operation_date', ascending: false),
    MovementHistoryRemoteOrder('created_at', ascending: false),
    MovementHistoryRemoteOrder('id', ascending: false),
  ];

  final LiveItemIdentity identity;
  final int offset;
  final int pageSize;
  final int fetchLimit;

  int get rangeEnd => offset + fetchLimit - 1;
}

@immutable
class MovementHistoryRemoteOrder {
  const MovementHistoryRemoteOrder(this.column, {required this.ascending});

  final String column;
  final bool ascending;
}

abstract interface class MovementHistoryRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchMovements(
    MovementHistoryRemoteQuery query,
  );
}
