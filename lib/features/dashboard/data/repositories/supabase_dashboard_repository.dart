import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
import '../../../../core/data/inventory_category_names.dart';
import '../../../inventory/model/inventory_item.dart';
import '../../../inventory/model/inventory_movement.dart';
import '../../model/dashboard_models.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_remote_data_source.dart';
import 'dashboard_repository.dart';

class SupabaseDashboardRepository implements DashboardRepository {
  const SupabaseDashboardRepository(this._dataSource);

  final DashboardRemoteDataSource _dataSource;

  @override
  Future<DataResult<DashboardData>> fetchDashboard({
    int attentionLimit = 10,
    int recentMovementLimit = 3,
  }) async {
    final safeAttentionLimit = attentionLimit < 0 ? 0 : attentionLimit;
    final safeMovementLimit = recentMovementLimit < 0 ? 0 : recentMovementLimit;
    try {
      final results = await Future.wait([
        _dataSource.fetchSummary(),
        _dataSource.fetchAttentionItems(limit: safeAttentionLimit),
        _dataSource.fetchRecentMovements(limit: safeMovementLimit),
      ]);
      final summary = results[0] as Map<String, dynamic>;
      final attentionRows = results[1] as List<Map<String, dynamic>>;
      final recentRows = results[2] as List<Map<String, dynamic>>;

      return DataSuccess(
        DashboardData(
          metrics: _metrics(summary),
          categories: _categories(summary),
          attentionItems: attentionRows
              .map(InventoryItem.fromInventorySummaryRow)
              .take(safeAttentionLimit)
              .toList(growable: false),
          recentMovements: recentRows
              .map(InventoryMovement.tryFromMovementViewRow)
              .whereType<InventoryMovement>()
              .take(safeMovementLimit)
              .toList(growable: false),
        ),
      );
    } on Object catch (error) {
      return DataError(SupabaseFailureMapper.from(error));
    }
  }

  List<DashboardMetric> _metrics(Map<String, dynamic> summary) {
    return [
      DashboardMetric(
        label: 'إجمالي الأصناف',
        value: _count(summary, const ['total_items', 'total', 'items_count']),
      ),
      DashboardMetric(
        label: 'مخزون منخفض',
        value: _count(summary, const ['low_stock', 'low_count']),
      ),
      DashboardMetric(
        label: 'نفد المخزون',
        value: _count(summary, const [
          'out_of_stock',
          'out_of_stock_count',
          'out_count',
        ]),
      ),
    ];
  }

  List<CategorySummary> _categories(Map<String, dynamic> summary) {
    final parsed = <CategorySummary>[];

    final legacyCounts = summary['category_counts'];
    if (legacyCounts is Map) {
      for (final entry in InventoryCategoryNames.legacyDisplayNames.entries) {
        final count = _numericCount(legacyCounts[entry.key]);
        if (count == null) continue;
        // `name` deliberately uses the value exposed by
        // inventory_category_items_summary_view.category_name. Dashboard
        // navigation passes it unchanged to the server-side category filter.
        parsed.add(
          CategorySummary(
            name: entry.value,
            itemCount: count,
            attentionCount: 0,
          ),
        );
      }
    }

    final dynamicCounts = summary['dynamic_category_counts'];
    if (dynamicCounts is List) {
      for (final entry in dynamicCounts) {
        if (entry is! Map) continue;
        final id = entry['category_id'];
        final name = entry['category_name'];
        final count = _numericCount(entry['row_count']);
        if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
          continue;
        }
        if (count == null) continue;

        parsed.add(
          CategorySummary(
            id: id,
            name: name,
            itemCount: count,
            attentionCount: 0,
          ),
        );
      }
    }
    return List.unmodifiable(parsed);
  }

  static int _count(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final count = _numericCount(json[key]);
      if (count != null) return count;
    }
    return 0;
  }

  static int? _numericCount(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return num.tryParse(value)?.toInt();
    return null;
  }
}
