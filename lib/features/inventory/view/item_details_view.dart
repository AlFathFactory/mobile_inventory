import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/responsive_page.dart';
import '../model/inventory_item.dart';
import '../model/inventory_movement.dart';
import '../widgets/item_details_header.dart';
import '../widgets/item_information_section.dart';
import '../widgets/item_notes_section.dart';
import '../widgets/item_recent_movements.dart';
import '../widgets/item_stock_overview.dart';

class ItemDetailsView extends StatelessWidget {
  const ItemDetailsView({
    required this.item,
    required this.movements,
    super.key,
  });

  final InventoryItem item;
  final List<InventoryMovement> movements;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الصنف')),
      body: SafeArea(
        top: false,
        child: ResponsivePage(
          child: ListView(
            key: const Key('item-details-list'),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              ItemDetailsHeader(item: item),
              const SizedBox(height: AppDimensions.space20),
              ItemStockOverview(item: item),
              const SizedBox(height: AppDimensions.space24),
              ItemInformationSection(item: item),
              if (item.notes case final notes?) ...[
                const SizedBox(height: AppDimensions.space20),
                ItemNotesSection(notes: notes),
              ],
              const SizedBox(height: AppDimensions.space24),
              ItemRecentMovements(
                movements: movements.take(2).toList(growable: false),
                onViewAll: movements.isEmpty
                    ? null
                    : () => context.pushNamed(
                        AppRouteNames.itemHistory,
                        pathParameters: {'code': item.code},
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
