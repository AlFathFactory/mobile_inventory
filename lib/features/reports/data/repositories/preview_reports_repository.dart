import '../../../../core/data/preview_data.dart';
import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../model/report_filter.dart';
import '../models/reports_data.dart';
import '../models/reports_query.dart';
import 'reports_repository.dart';

class PreviewReportsRepository implements ReportsRepository {
  const PreviewReportsRepository();

  @override
  Future<DataResult<ReportsData>> fetchReports(ReportsQuery query) async {
    final search = query.search.trim().toLowerCase();
    final start = _dateOnly(query.startDate);
    final end = _dateOnly(query.endDate);
    final movements = PreviewData.reportMovements
        .where((movement) {
          final movementDate = _dateOnly(movement.date)!;
          final matchesSearch =
              search.isEmpty ||
              movement.itemName.toLowerCase().contains(search) ||
              movement.itemCode.toLowerCase().contains(search);
          final matchesType =
              query.types.isEmpty || query.types.contains(movement.type);
          final matchesCategory =
              query.categories.isEmpty ||
              query.categories.contains(movement.category);
          final matchesProject =
              query.projects.isEmpty ||
              query.projects.contains(movement.project);
          final matchesStart = start == null || !movementDate.isBefore(start);
          final matchesEnd = end == null || !movementDate.isAfter(end);
          return matchesSearch &&
              matchesType &&
              matchesCategory &&
              matchesProject &&
              matchesStart &&
              matchesEnd;
        })
        .toList(growable: false);

    return DataSuccess(
      ReportsData(
        snapshot: const ReportSnapshot(total: 128, issues: 74, additions: 39),
        movements: paginatePreview(movements, query.page),
      ),
    );
  }

  DateTime? _dateOnly(DateTime? value) =>
      value == null ? null : DateTime(value.year, value.month, value.day);
}
