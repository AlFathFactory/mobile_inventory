import 'dart:math' as math;

import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
import '../../../inventory/model/inventory_item.dart';
import '../../model/alert_summary.dart';
import '../models/alerts_data.dart';
import '../models/alerts_query.dart';
import '../services/alerts_remote_data_source.dart';
import 'alerts_repository.dart';

class SupabaseAlertsRepository implements AlertsRepository {
  const SupabaseAlertsRepository(this._dataSource);

  final AlertsRemoteDataSource _dataSource;

  @override
  Future<DataResult<AlertsData>> fetchAlerts(AlertsQuery query) async {
    try {
      final remoteQuery = AlertsRemoteQuery.fromAlertsQuery(query);
      final counts = await Future.wait<int>([
        _dataSource.countAlerts(remoteQuery, status: StockStatus.low),
        _dataSource.countAlerts(remoteQuery, status: StockStatus.outOfStock),
      ]);
      final summary = AlertSummary(
        lowCount: counts[0],
        outOfStockCount: counts[1],
      );

      if (remoteQuery.statuses.isEmpty) {
        return DataSuccess(
          AlertsData(
            summary: summary,
            alerts: PageResult(items: const <InventoryItem>[]),
          ),
        );
      }

      final countByStatus = <StockStatus, int>{
        StockStatus.low: summary.lowCount,
        StockStatus.outOfStock: summary.outOfStockCount,
      };
      var segmentOffset = remoteQuery.offset;
      final rows = <Map<String, dynamic>>[];

      for (final status in remoteQuery.statuses) {
        final segmentCount = countByStatus[status] ?? 0;
        if (segmentOffset >= segmentCount) {
          segmentOffset -= segmentCount;
          continue;
        }

        final remaining = remoteQuery.fetchLimit - rows.length;
        if (remaining <= 0) break;
        final available = segmentCount - segmentOffset;
        final requestLimit = math.min(remaining, available);
        rows.addAll(
          await _dataSource.fetchAlerts(
            remoteQuery,
            status: status,
            offset: segmentOffset,
            limit: requestLimit,
          ),
        );
        segmentOffset = 0;
      }

      final hasMore = rows.length > remoteQuery.pageSize;
      final pageRows = hasMore ? rows.take(remoteQuery.pageSize) : rows;
      return DataSuccess(
        AlertsData(
          summary: summary,
          alerts: PageResult(
            items: pageRows
                .map(InventoryItem.fromInventorySummaryRow)
                .toList(growable: false),
            nextCursor: hasMore
                ? '${remoteQuery.offset + remoteQuery.pageSize}'
                : null,
          ),
        ),
      );
    } on Object catch (error) {
      return DataError(SupabaseFailureMapper.from(error));
    }
  }
}
