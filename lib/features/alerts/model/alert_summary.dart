import 'package:flutter/foundation.dart';

@immutable
class AlertSummary {
  const AlertSummary({required this.lowCount, required this.outOfStockCount});

  final int lowCount;
  final int outOfStockCount;
}
