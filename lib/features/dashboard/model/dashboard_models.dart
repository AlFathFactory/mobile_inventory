import 'package:flutter/foundation.dart';

import '../../../core/data/json_map_reader.dart';

@immutable
class DashboardMetric {
  const DashboardMetric({required this.label, required this.value});

  factory DashboardMetric.fromJson(Map<String, dynamic> json) {
    return DashboardMetric(
      label: JsonMapReader.string(json, 'label'),
      value: JsonMapReader.integer(json, 'value'),
    );
  }

  final String label;
  final int value;
}

@immutable
class CategorySummary {
  const CategorySummary({
    required this.name,
    required this.itemCount,
    required this.attentionCount,
    this.id,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      id: JsonMapReader.nullableString(json, 'id'),
      name: JsonMapReader.string(json, 'name'),
      itemCount: JsonMapReader.integer(json, 'item_count'),
      attentionCount: JsonMapReader.integer(json, 'attention_count'),
    );
  }

  final String? id;
  final String name;
  final int itemCount;
  final int attentionCount;
}
