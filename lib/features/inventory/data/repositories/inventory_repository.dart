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
}

/// Optional capability implemented only by repositories with a local cache.
abstract interface class InventoryCacheRefreshable {
  Future<void> refreshCache();
}
