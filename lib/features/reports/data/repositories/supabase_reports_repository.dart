import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
import '../../../inventory/model/inventory_movement.dart';
import '../../model/report_filter.dart';
import '../models/reports_data.dart';
import '../models/reports_query.dart';
import '../services/reports_remote_data_source.dart';
import 'reports_repository.dart';

class SupabaseReportsRepository implements ReportsRepository {
  const SupabaseReportsRepository(this._source);

  final ReportsRemoteDataSource _source;

  @override
  Future<DataResult<ReportsData>> fetchReports(ReportsQuery query) async {
    try {
      final remote = ReportsRemoteQuery.fromQuery(query);
      final response = await _source.fetchReports(remote);
      final summary = response.aggregated['summary'];
      if (summary is! Map) {
        throw const FormatException('Missing aggregate reports summary.');
      }
      final values = Map<String, dynamic>.from(summary);
      final hasMore = response.rows.length > remote.pageSize;
      final movements = response.rows
          .take(remote.pageSize)
          .map(InventoryMovement.tryFromMovementViewRow)
          .whereType<InventoryMovement>()
          .toList(growable: false);
      return DataSuccess(
        ReportsData(
          snapshot: ReportSnapshot(
            total: response.totalMovements,
            issues: _count(values, 'issue_operations_count'),
            additions: _count(values, 'addition_operations_count'),
          ),
          movements: PageResult(
            items: movements,
            nextCursor: hasMore ? '${remote.offset + remote.pageSize}' : null,
          ),
        ),
      );
    } on Object catch (error) {
      return DataError(SupabaseFailureMapper.from(error));
    }
  }

  @override
  Future<DataResult<ReportsFilterOptions>> fetchFilterOptions() async {
    try {
      return DataSuccess(await _source.fetchFilterOptions());
    } on Object catch (error) {
      return DataError(SupabaseFailureMapper.from(error));
    }
  }

  int _count(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.parse(raw);
    throw FormatException('Missing aggregate reports metric "$key".');
  }
}
