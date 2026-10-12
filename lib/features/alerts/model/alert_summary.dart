import 'package:flutter/foundation.dart';

import '../../../core/data/json_map_reader.dart';

@immutable
class AlertSummary {
  const AlertSummary({required this.lowCount, required this.outOfStockCount});

  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    return AlertSummary(
      lowCount: JsonMapReader.integer(json, 'low_count'),
      outOfStockCount: JsonMapReader.integer(json, 'out_of_stock_count'),
    );
  }

  final int lowCount;
  final int outOfStockCount;
}
