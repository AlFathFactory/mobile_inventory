import '../../../../core/data/repositories/data_result.dart';
import '../models/reports_data.dart';
import '../models/reports_query.dart';
import '../services/reports_remote_data_source.dart';

abstract interface class ReportsRepository {
  Future<DataResult<ReportsData>> fetchReports(ReportsQuery query);
  Future<DataResult<ReportsFilterOptions>> fetchFilterOptions();
}
