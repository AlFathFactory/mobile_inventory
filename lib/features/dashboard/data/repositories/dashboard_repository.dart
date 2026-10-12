import '../../../../core/data/repositories/data_result.dart';
import '../models/dashboard_data.dart';

abstract interface class DashboardRepository {
  Future<DataResult<DashboardData>> fetchDashboard({
    int attentionLimit = 10,
    int recentMovementLimit = 3,
  });
}
