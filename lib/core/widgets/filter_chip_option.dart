import 'package:flutter/material.dart';

class FilterChipOption<T> {
  const FilterChipOption({
    required this.value,
    required this.label,
    this.foreground,
    this.background,
  });

  final T value;
  final String label;
  final Color? foreground;
  final Color? background;
}
