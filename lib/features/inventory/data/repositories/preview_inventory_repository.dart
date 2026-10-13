import '../../../../core/data/preview_data.dart';
import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../model/inventory_item.dart';
import '../../model/inventory_movement.dart';
import '../models/inventory_query.dart';
import '../models/movement_history_query.dart';
import 'inventory_repository.dart';
import 'item_details_repository.dart';
import 'movement_history_repository.dart';

class PreviewInventoryRepository
    implements
        InventoryRepository,
        ItemDetailsRepository,
        MovementHistoryRepository {
  const PreviewInventoryRepository();

  @override
  Future<DataResult<PageResult<InventoryItem>>> fetchItems(
    InventoryQuery query,
  ) async {
    final search = query.search.trim().toLowerCase();
    final items = PreviewData.catalogItems
        .where((item) {
          final matchesSearch =
              search.isEmpty ||
              item.name.toLowerCase().contains(search) ||
              item.code.toLowerCase().contains(search);
          final matchesStatus =
              query.statuses.isEmpty || query.statuses.contains(item.status);
          final matchesCategory =
              query.categories.isEmpty ||
              query.categories.contains(item.category);
          final matchesProject =
              query.projects.isEmpty || query.projects.contains(item.project);
          return matchesSearch &&
              matchesStatus &&
              matchesCategory &&
              matchesProject;
        })
        .toList(growable: false);
    return DataSuccess(paginatePreview(items, query.page));
  }

  @override
  Future<DataResult<InventoryItem?>> fetchItemByRouteId(String routeId) async {
    for (final item in PreviewData.items) {
      if (item.routeId == routeId) return DataSuccess(item);
    }
    return const DataSuccess(null);
  }

  @override
  Future<DataResult<PageResult<InventoryMovement>>> fetchMovements(
    MovementHistoryQuery query,
  ) async {
    final movements = PreviewData.movementsFor(query.itemRouteId);
    return DataSuccess(paginatePreview(movements, query.page));
  }
}
