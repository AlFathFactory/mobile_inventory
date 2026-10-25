import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_dimensions.dart';
import 'responsive_page.dart';

/// A dashboard-shaped loading surface used while startup or its first route
/// waits for data. It contains no live controls or preview records.
class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ResponsivePage(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const SizedBox(height: AppDimensions.space16),
            const Text('متابعة المخزون', style: TextStyle(fontSize: 28)),
            const SizedBox(height: AppDimensions.space16),
            const _SkeletonCard(lines: 1, height: 72),
            const SizedBox(height: AppDimensions.space24),
            const Text('نظرة عامة', style: TextStyle(fontSize: 22)),
            const SizedBox(height: AppDimensions.space12),
            const Row(
              children: [
                Expanded(child: _SkeletonCard(lines: 2, height: 120)),
                SizedBox(width: 10),
                Expanded(child: _SkeletonCard(lines: 2, height: 120)),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),
            const Text('التصنيفات', style: TextStyle(fontSize: 22)),
            const SizedBox(height: AppDimensions.space12),
            const _SkeletonCard(lines: 2, height: 120),
            const SizedBox(height: AppDimensions.space8),
            const _SkeletonCard(lines: 2, height: 120),
            const SizedBox(height: AppDimensions.space24),
            const Text('تحتاج إلى متابعة', style: TextStyle(fontSize: 22)),
            const SizedBox(height: AppDimensions.space12),
            const _SkeletonCard(lines: 2, height: 120),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.lines, required this.height});

  final int lines;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < lines; index++) ...[
                Text(
                  index == 0 ? 'بيانات المخزون المحفوظة' : 'متابعة الأصناف',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (index + 1 < lines) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
