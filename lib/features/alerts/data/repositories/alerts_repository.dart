import '../../../../core/data/repositories/data_result.dart';
import '../models/alerts_data.dart';
import '../models/alerts_query.dart';

abstract interface class AlertsRepository {
  Future<DataResult<AlertsData>> fetchAlerts(AlertsQuery query);
}
