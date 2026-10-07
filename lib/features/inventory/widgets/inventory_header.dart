import 'package:flutter/material.dart';

import '../../../core/widgets/page_header.dart';

class InventoryHeader extends StatelessWidget {
  const InventoryHeader({required this.totalCount, super.key});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'المخزون',
      subtitle: 'تصفّح الأصناف وتابع حالة توفرها',
      trailing: PageCountBadge(value: totalCount, label: 'صنف'),
    );
  }
}
