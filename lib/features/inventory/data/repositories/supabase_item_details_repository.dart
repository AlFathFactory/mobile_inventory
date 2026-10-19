import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
import '../../model/inventory_item.dart';
import '../models/live_item_identity.dart';
import '../services/item_details_remote_data_source.dart';
import 'item_details_repository.dart';

class SupabaseItemDetailsRepository implements ItemDetailsRepository {
  const SupabaseItemDetailsRepository(this._dataSource);

  final ItemDetailsRemoteDataSource _dataSource;

  @override
  Future<DataResult<InventoryItem?>> fetchItemByRouteId(String routeId) async {
    final identity = LiveItemIdentity.tryParse(routeId);
    if (identity == null) {
      return const DataError(
        DataFailure(
          kind: DataFailureKind.unknown,
          message: 'The selected item identity is invalid.',
        ),
      );
    }

    try {
      final row = await _dataSource.fetchItem(
        ItemDetailsRemoteQuery(
          tableName: identity.tableName,
          itemId: identity.itemId,
        ),
      );
      if (row == null) return const DataSuccess(null);

      var item = InventoryItem.fromInventorySummaryRow(row);
      if (item.tableName != identity.tableName ||
          item.itemId != identity.itemId) {
        throw const FormatException('Item identity does not match its row.');
      }

      if (identity.tableName == 'paints') {
        item = item.withProductionDate(
          await _dataSource.fetchPaintProductionDate(identity.itemId),
        );
      }
      return DataSuccess(item);
    } on Object catch (error) {
      return DataError(SupabaseFailureMapper.from(error));
    }
  }
}
