import 'package:flutter/material.dart';

import '../../../core/widgets/page_header.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({required this.onNotificationsTap, super.key});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'أهلًا، صباح الخير 👋',
      subtitle: 'إليك حالة المخزون اليوم · المخزن الرئيسي',
      icon: Icons.notifications_none_rounded,
      iconKey: const Key('dashboard-notifications'),
      iconTooltip: 'التنبيهات',
      onIconTap: onNotificationsTap,
    );
  }
}
