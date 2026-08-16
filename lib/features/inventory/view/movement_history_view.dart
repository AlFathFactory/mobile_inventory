import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_components.dart';
import '../model/inventory_item.dart';
import '../model/inventory_movement.dart';
import '../widgets/movement_card.dart';

class MovementHistoryView extends StatelessWidget {
  const MovementHistoryView({
    required this.item,
    required this.movements,
    super.key,
  });

  final InventoryItem item;
  final List<InventoryMovement> movements;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الحركات')),
      body: SafeArea(
        top: false,
        child: ResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppTextStyles.sectionTitle),
              const SizedBox(height: 3),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(item.code, style: AppTextStyles.code),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  key: const Key('movement-history-list'),
                  itemCount: movements.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      MovementCard(movement: movements[index], showItem: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
