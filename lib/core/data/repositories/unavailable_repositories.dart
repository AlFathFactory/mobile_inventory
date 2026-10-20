import 'data_result.dart';
import 'page.dart';
import '../../../features/alerts/data/models/alerts_data.dart';
import '../../../features/alerts/data/models/alerts_query.dart';
import '../../../features/alerts/data/repositories/alerts_repository.dart';
import '../../../features/dashboard/data/models/dashboard_data.dart';
import '../../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../../features/inventory/data/models/inventory_query.dart';
import '../../../features/inventory/data/models/movement_history_query.dart';
import '../../../features/inventory/data/repositories/inventory_repository.dart';
import '../../../features/inventory/data/repositories/item_details_repository.dart';
import '../../../features/inventory/data/repositories/movement_history_repository.dart';
import '../../../features/inventory/model/inventory_item.dart';
import '../../../features/inventory/model/inventory_movement.dart';
import '../../../features/reports/data/models/reports_data.dart';
import '../../../features/reports/data/models/reports_query.dart';
import '../../../features/reports/data/repositories/reports_repository.dart';
import '../../../features/reports/data/services/reports_remote_data_source.dart';

const unavailableFailure = DataFailure(
  kind: DataFailureKind.unavailable,
  message: 'تعذر الاتصال بخدمة البيانات. حاول مرة أخرى.',
);

class UnavailableInventoryRepository implements InventoryRepository {
  const UnavailableInventoryRepository();

  @override
  Future<DataResult<List<String>>> fetchCategories() async =>
      const DataError(unavailableFailure);

  @override
  Future<DataResult<PageResult<InventoryItem>>> fetchItems(
    InventoryQuery query,
  ) async => const DataError(unavailableFailure);
}

class UnavailableDashboardRepository implements DashboardRepository {
  const UnavailableDashboardRepository();

  @override
  Future<DataResult<DashboardData>> fetchDashboard({
    int attentionLimit = 10,
    int recentMovementLimit = 3,
  }) async => const DataError(unavailableFailure);
}

class UnavailableAlertsRepository implements AlertsRepository {
  const UnavailableAlertsRepository();

  @override
  Future<DataResult<AlertsData>> fetchAlerts(AlertsQuery query) async =>
      const DataError(unavailableFailure);
}

class UnavailableReportsRepository implements ReportsRepository {
  const UnavailableReportsRepository();

  @override
  Future<DataResult<ReportsData>> fetchReports(ReportsQuery query) async =>
      const DataError(unavailableFailure);

  @override
  Future<DataResult<ReportsFilterOptions>> fetchFilterOptions() async =>
      const DataError(unavailableFailure);
}

class UnavailableItemDetailsRepository implements ItemDetailsRepository {
  const UnavailableItemDetailsRepository();

  @override
  Future<DataResult<InventoryItem?>> fetchItemByRouteId(String routeId) async =>
      const DataError(unavailableFailure);
}

class UnavailableMovementHistoryRepository
    implements MovementHistoryRepository {
  const UnavailableMovementHistoryRepository();

  @override
  Future<DataResult<PageResult<InventoryMovement>>> fetchMovements(
    MovementHistoryQuery query,
  ) async => const DataError(unavailableFailure);
}
