import '../../../../core/data/preview_data.dart';
import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../../../core/utils/search_normalizer.dart';
import '../../model/report_filter.dart';
import '../models/reports_data.dart';
import '../models/reports_query.dart';
import '../services/reports_remote_data_source.dart';
import 'reports_repository.dart';

class PreviewReportsRepository implements ReportsRepository {
  const PreviewReportsRepository();

  @override
  Future<DataResult<ReportsData>> fetchReports(ReportsQuery query) async {
    final search = normalizeSearchTerm(query.search);
    final start = _dateOnly(query.startDate);
    final end = _dateOnly(query.endDate);
    final movements = PreviewData.reportMovements
        .where((movement) {
          final movementDate = _dateOnly(movement.date)!;
          final matchesSearch = matchesAnySearchValue([
            movement.itemName,
            movement.itemCode,
            movement.project,
            movement.category,
          ], search);
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

  @override
  Future<DataResult<ReportsFilterOptions>> fetchFilterOptions() async =>
      DataSuccess(
        ReportsFilterOptions(
          categories:
              PreviewData.reportMovements
                  .map((movement) => movement.category)
                  .toSet()
                  .toList()
                ..sort(),
          projects:
              PreviewData.reportMovements
                  .map((movement) => movement.project)
                  .toSet()
                  .toList()
                ..sort(),
        ),
      );
}
