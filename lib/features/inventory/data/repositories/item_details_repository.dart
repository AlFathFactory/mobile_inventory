import '../../../../core/data/repositories/data_result.dart';
import '../../model/inventory_item.dart';

abstract interface class ItemDetailsRepository {
  Future<DataResult<InventoryItem?>> fetchItemByCode(String code);
}
