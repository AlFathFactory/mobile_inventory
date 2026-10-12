import 'package:flutter/foundation.dart';

import '../../../core/data/json_map_reader.dart';

enum ReportPeriod { last30Days, all, custom }

@immutable
class ReportSnapshot {
  const ReportSnapshot({
    required this.total,
    required this.issues,
    required this.additions,
  });

  factory ReportSnapshot.fromJson(Map<String, dynamic> json) {
    return ReportSnapshot(
      total: JsonMapReader.integer(json, 'total'),
      issues: JsonMapReader.integer(json, 'issues'),
      additions: JsonMapReader.integer(json, 'additions'),
    );
  }

  final int total;
  final int issues;
  final int additions;
}
