import 'package:flutter/material.dart';

import '../../../core/widgets/page_header.dart';

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({required this.totalCount, super.key});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'التقارير',
      subtitle: 'استكشف حركة المخزون واتجاهاتها',
      trailing: PageCountBadge(value: totalCount, label: 'حركة'),
    );
  }
}
