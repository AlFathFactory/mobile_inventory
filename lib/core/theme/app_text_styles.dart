import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const fontFamily = 'IBMPlexSansArabic';

  static const screenTitle = TextStyle(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const pageTitle = TextStyle(
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const sectionTitle = TextStyle(
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 13,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );
  static const label = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral700,
  );
  static const caption = TextStyle(
    fontSize: 11,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral700,
  );
  static const number = TextStyle(
    fontSize: 23,
    height: 1.05,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const code = TextStyle(
    fontSize: 11.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
