import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/page.dart';

@immutable
class MovementHistoryQuery {
  const MovementHistoryQuery({
    required this.itemRouteId,
    this.page = const PageRequest(),
  });

  final String itemRouteId;
  final PageRequest page;
}
