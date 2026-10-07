import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final defaultPadding = MediaQuery.sizeOf(context).width <= 360
        ? AppDimensions.compactPagePadding
        : AppDimensions.pagePadding;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.pageMaxWidth),
        child: Padding(padding: padding ?? defaultPadding, child: child),
      ),
    );
  }
}
