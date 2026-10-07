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

class ItemDetailsView extends StatefulWidget {
  const ItemDetailsView({
    required this.item,
    required this.movements,
    this.onBack,
    super.key,
  });

  final InventoryItem item;
  final List<InventoryMovement> movements;
  final VoidCallback? onBack;

  @override
  State<ItemDetailsView> createState() => _ItemDetailsViewState();
}

class _ItemDetailsViewState extends State<ItemDetailsView> {
  bool _isOpeningHistory = false;

  void _openHistory() {
    if (_isOpeningHistory || widget.movements.isEmpty) return;

    _isOpeningHistory = true;
    context
        .pushNamed<void>(
          AppRouteNames.itemHistory,
          pathParameters: {'code': widget.item.code},
        )
        .then<void>(
          (_) => _isOpeningHistory = false,
          onError: (_, _) => _isOpeningHistory = false,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الصنف'),
        leading: widget.onBack == null
            ? null
            : BackButton(
                key: const Key('item-details-back'),
                onPressed: widget.onBack,
              ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsivePage(
          child: ListView(
            key: const Key('item-details-list'),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              ItemDetailsHeader(item: widget.item),
              const SizedBox(height: AppDimensions.space20),
              ItemStockOverview(item: widget.item),
              const SizedBox(height: AppDimensions.space24),
              ItemInformationSection(item: widget.item),
              if (widget.item.notes case final notes?) ...[
                const SizedBox(height: AppDimensions.space20),
                ItemNotesSection(notes: notes),
              ],
              const SizedBox(height: AppDimensions.space24),
              ItemRecentMovements(
                movements: widget.movements.take(2).toList(growable: false),
                onViewAll: widget.movements.isEmpty ? null : _openHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
