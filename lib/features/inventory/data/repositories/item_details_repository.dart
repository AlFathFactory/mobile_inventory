import '../../../../core/data/repositories/data_result.dart';
import '../../model/inventory_item.dart';

abstract interface class ItemDetailsRepository {
  /// Resolves a preview code or a live `table_name::item_id` route identity.
  Future<DataResult<InventoryItem?>> fetchItemByRouteId(String routeId);
}
