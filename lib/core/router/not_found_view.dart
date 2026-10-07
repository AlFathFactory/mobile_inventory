import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../widgets/app_components.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: context.canPop(),
        title: const Text('الصفحة غير موجودة'),
      ),
      body: SafeArea(
        child: ResponsivePage(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyState(
                title: 'الصفحة غير موجودة',
                message: 'تعذّر العثور على الصنف أو المسار المطلوب.',
              ),
              TextButton.icon(
                key: const Key('not-found-dashboard'),
                onPressed: () => context.goNamed(AppRouteNames.dashboard),
                icon: const Icon(Icons.home_outlined),
                label: const Text('العودة إلى الرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
