import '../../../../core/data/preview_data.dart';
import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../../inventory/model/inventory_item.dart';
import '../../model/alert_summary.dart';
import '../models/alerts_data.dart';
import '../models/alerts_query.dart';
import 'alerts_repository.dart';

class PreviewAlertsRepository implements AlertsRepository {
  const PreviewAlertsRepository({this.items});

  final List<InventoryItem>? items;

  @override
  Future<DataResult<AlertsData>> fetchAlerts(AlertsQuery query) async {
    final search = query.search.trim().toLowerCase();
    final sourceItems = items ?? PreviewData.alertItems;
    final filteredItems =
        sourceItems.where((item) {
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
        }).toList()..sort((left, right) {
          final severity = _severity(
            right.status,
          ).compareTo(_severity(left.status));
          if (severity != 0) return severity;
          return left.routeId.compareTo(right.routeId);
        });

    return DataSuccess(
      AlertsData(
        summary: items == null
            ? const AlertSummary(lowCount: 14, outOfStockCount: 3)
            : AlertSummary(
                lowCount: sourceItems
                    .where((item) => item.status == StockStatus.low)
                    .length,
                outOfStockCount: sourceItems
                    .where((item) => item.status == StockStatus.outOfStock)
                    .length,
              ),
        alerts: paginatePreview(filteredItems, query.page),
      ),
    );
  }

  static int _severity(StockStatus status) => switch (status) {
    StockStatus.outOfStock => 2,
    StockStatus.low => 1,
    StockStatus.safe => 0,
  };
}
