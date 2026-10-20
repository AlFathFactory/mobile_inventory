import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../model/inventory_item.dart';
import '../models/inventory_query.dart';

abstract interface class InventoryRepository {
  Future<DataResult<PageResult<InventoryItem>>> fetchItems(
    InventoryQuery query,
  );

  Future<DataResult<List<String>>> fetchCategories() async =>
      const DataSuccess([]);

  /// Refreshes the complete local snapshot when this repository has one.
  /// Preview and direct remote implementations remain no-ops.
  Future<void> refreshCache() async {}
}
