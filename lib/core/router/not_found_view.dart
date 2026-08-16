import 'package:flutter/material.dart';

import '../widgets/app_components.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ResponsivePage(
          child: EmptyState(
            title: 'الصفحة غير موجودة',
            message: 'تعذّر العثور على الصنف أو المسار المطلوب.',
          ),
        ),
      ),
    );
  }
}
