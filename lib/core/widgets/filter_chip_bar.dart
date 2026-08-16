import 'package:flutter/material.dart';

import 'filter_chip_option.dart';

class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<FilterChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChip(
              key: ValueKey(option.label),
              label: Text(option.label),
              selected: option.value == selected,
              onSelected: (_) => onSelected(option.value),
              showCheckmark: false,
            ),
            if (option != options.last) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}
