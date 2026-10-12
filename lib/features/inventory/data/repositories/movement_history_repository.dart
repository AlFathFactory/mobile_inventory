import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../model/inventory_movement.dart';
import '../models/movement_history_query.dart';

abstract interface class MovementHistoryRepository {
  Future<DataResult<PageResult<InventoryMovement>>> fetchMovements(
    MovementHistoryQuery query,
  );
}
