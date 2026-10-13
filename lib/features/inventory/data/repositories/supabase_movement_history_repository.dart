import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
import '../../model/inventory_movement.dart';
import '../models/live_item_identity.dart';
import '../models/movement_history_query.dart';
import '../services/movement_history_remote_data_source.dart';
import 'movement_history_repository.dart';

class SupabaseMovementHistoryRepository implements MovementHistoryRepository {
  const SupabaseMovementHistoryRepository(this._dataSource);

  final MovementHistoryRemoteDataSource _dataSource;

  @override
  Future<DataResult<PageResult<InventoryMovement>>> fetchMovements(
    MovementHistoryQuery query,
  ) async {
    final identity = LiveItemIdentity.tryParse(query.itemRouteId);
    if (identity == null) {
      return const DataError(
        DataFailure(
          kind: DataFailureKind.unknown,
          message: 'The selected item identity is invalid.',
        ),
      );
    }

    try {
      final remoteQuery = MovementHistoryRemoteQuery.fromQuery(query, identity);
      final rows = await _dataSource.fetchMovements(remoteQuery);
      final hasMore = rows.length > remoteQuery.pageSize;
      final pageRows = hasMore ? rows.take(remoteQuery.pageSize) : rows;
      final movements = <InventoryMovement>[];

      for (final row in pageRows) {
        if (row['table_name'] != identity.tableName ||
            row['item_id']?.toString() != identity.itemId) {
          throw const FormatException(
            'Movement identity does not match the requested item.',
          );
        }
        final movement = InventoryMovement.tryFromMovementViewRow(row);
        if (movement != null) movements.add(movement);
      }

      return DataSuccess(
        PageResult(
          items: movements,
          nextCursor: hasMore
              ? '${remoteQuery.offset + remoteQuery.pageSize}'
              : null,
        ),
      );
    } on Object catch (error) {
      return DataError(SupabaseFailureMapper.from(error));
    }
  }
}
