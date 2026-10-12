import '../../../../core/data/preview_data.dart';
import '../../../../core/data/repositories/data_result.dart';
import '../models/dashboard_data.dart';
import 'dashboard_repository.dart';

class PreviewDashboardRepository implements DashboardRepository {
  const PreviewDashboardRepository();

  @override
  Future<DataResult<DashboardData>> fetchDashboard({
    int attentionLimit = 10,
    int recentMovementLimit = 3,
  }) async {
    final safeAttentionLimit = attentionLimit < 0 ? 0 : attentionLimit;
    final safeMovementLimit = recentMovementLimit < 0 ? 0 : recentMovementLimit;
    return DataSuccess(
      DashboardData(
        metrics: PreviewData.dashboardMetrics,
        categories: PreviewData.categories,
        attentionItems: PreviewData.alertItems
            .take(safeAttentionLimit)
            .toList(growable: false),
        recentMovements: PreviewData.reportMovements
            .take(safeMovementLimit)
            .toList(growable: false),
      ),
    );
  }
}
