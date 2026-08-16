import 'package:flutter/foundation.dart';

@immutable
class DashboardMetric {
  const DashboardMetric({required this.label, required this.value});

  final String label;
  final int value;
}

@immutable
class CategorySummary {
  const CategorySummary({
    required this.name,
    required this.itemCount,
    required this.attentionCount,
  });

  final String name;
  final int itemCount;
  final int attentionCount;
}
