import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/page.dart';

@immutable
class MovementHistoryQuery {
  const MovementHistoryQuery({
    required this.itemCode,
    this.page = const PageRequest(),
  });

  final String itemCode;
  final PageRequest page;
}
