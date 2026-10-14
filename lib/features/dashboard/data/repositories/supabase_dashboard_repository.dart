import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
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
    final raw = summary['categories'];
    if (raw is! List) return const [];
    final parsed = <CategorySummary>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final row = Map<String, dynamic>.from(entry);
      final name = _text(row, const ['name', 'category_name']);
      if (name == null) continue;
      parsed.add(
        CategorySummary(
          id: _text(row, const ['id', 'category_id', 'uuid']),
          name: name,
          itemCount: _count(row, const [
            'item_count',
            'items_count',
            'total_items',
            'total',
            'count',
          ]),
          attentionCount: _count(row, const [
            'attention_count',
            'attention',
            'low_count',
            'alerts_count',
          ]),
        ),
      );
    }
    return List.unmodifiable(parsed);
  }

  static String? _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
      if (value is num) return value.toString();
    }
    return null;
  }

  static int _count(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed.toInt();
      }
    }
    return 0;
  }
}
