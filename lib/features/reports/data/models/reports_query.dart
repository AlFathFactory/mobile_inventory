import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/page.dart';
import '../../../inventory/model/inventory_movement.dart';

@immutable
class ReportsQuery {
  const ReportsQuery({
    this.page = const PageRequest(),
    this.search = '',
    this.types = const {},
    this.categories = const {},
    this.projects = const {},
    this.startDate,
    this.endDate,
  });

  final PageRequest page;
  final String search;
  final Set<MovementType> types;
  final Set<String> categories;
  final Set<String> projects;
  final DateTime? startDate;
  final DateTime? endDate;
}
