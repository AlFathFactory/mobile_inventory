import 'package:flutter/foundation.dart';

enum ReportPeriod { last30Days, all, custom }

@immutable
class ReportSnapshot {
  const ReportSnapshot({
    required this.total,
    required this.issues,
    required this.additions,
  });

  final int total;
  final int issues;
  final int additions;
}
