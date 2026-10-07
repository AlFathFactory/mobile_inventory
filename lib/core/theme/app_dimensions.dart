import 'package:flutter/material.dart';

/// Shared layout tokens used across the app's read-only surfaces.
abstract final class AppDimensions {
  static const double pageMaxWidth = 600;

  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double radiusSmall = 12;
  static const double radiusControl = 16;
  static const double radiusCard = 20;
  static const double radiusLarge = 24;

  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;

  static const double minTouchTarget = 48;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 12, 20, 24);
  static const EdgeInsets compactPagePadding = EdgeInsets.fromLTRB(
    16,
    12,
    16,
    16,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
}
