import '../../../../core/data/preview_data.dart';
import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../model/alert_summary.dart';
import '../models/alerts_data.dart';
import '../models/alerts_query.dart';
import 'alerts_repository.dart';

class PreviewAlertsRepository implements AlertsRepository {
  const PreviewAlertsRepository();

  @override
  Future<DataResult<AlertsData>> fetchAlerts(AlertsQuery query) async {
    final search = query.search.trim().toLowerCase();
    final items = PreviewData.alertItems
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
          return matchesSearch && matchesStatus && matchesCategory;
        })
        .toList(growable: false);

    return DataSuccess(
      AlertsData(
        summary: const AlertSummary(lowCount: 14, outOfStockCount: 3),
        alerts: paginatePreview(items, query.page),
      ),
    );
  }
}
