import '../../../../core/data/repositories/data_result.dart';
import '../models/reports_data.dart';
import '../models/reports_query.dart';

abstract interface class ReportsRepository {
  Future<DataResult<ReportsData>> fetchReports(ReportsQuery query);
}
