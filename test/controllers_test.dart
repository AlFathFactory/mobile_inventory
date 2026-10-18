import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/features/alerts/cubit/alerts_cubit.dart';
import 'package:el_fateh/features/alerts/data/repositories/preview_alerts_repository.dart';
import 'package:el_fateh/features/inventory/cubit/inventory_cubit.dart';
import 'package:el_fateh/features/inventory/model/inventory_filter.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:el_fateh/features/inventory/model/inventory_movement.dart';
import 'package:el_fateh/features/reports/cubit/reports_cubit.dart';
import 'package:el_fateh/features/reports/model/report_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryItem', () {
    test('derives each stock status from quantity and minimum', () {
      expect(PreviewData.itemByCode('PA-GN-059').status, StockStatus.safe);
      expect(PreviewData.itemByCode('HW-SC-112').status, StockStatus.low);
      expect(
        PreviewData.itemByCode('GS-OX-004').status,
        StockStatus.outOfStock,
      );
    });
  });

  group('InventoryCubit', () {
    late InventoryCubit controller;

    setUp(() {
      controller = InventoryCubit(
        items: PreviewData.catalogItems,
        initiallyLoading: false,
      );
    });

    tearDown(() => controller.close());

    test('searches Arabic names and Latin item codes', () {
      controller.setQuery('مسامير');
      expect(controller.visibleItems.single.code, 'HW-SC-112');

      controller.setQuery('el-cb-025');
      expect(controller.visibleItems.single.name, contains('كابل كهرباء'));
    });

    test('combines advanced status, category, and project filters', () {
      controller.applyFilters(
        const InventoryFilter(
          statuses: {StockStatus.low},
          categories: {'مخزن الكهرباء'},
          projects: {'AMSET 2'},
        ),
      );

      expect(controller.visibleItems.single.code, 'EL-CB-025');
      controller.clearFilters();
      expect(controller.visibleItems, hasLength(6));
    });

    test('quick status and dashboard category filters work', () {
      controller.setQuickStatus(StockStatus.outOfStock);
      expect(controller.visibleItems.single.code, 'GS-OX-004');

      controller.setQuery('GS-OX-004');
      controller.filterByCategory('الدهانات');
      expect(controller.quickStatus, isNull);
      expect(controller.query, isEmpty);
      expect(controller.visibleItems.single.code, 'PA-GN-059');
    });

    test('category browsing preserves other advanced filters', () {
      controller.applyFilters(const InventoryFilter(projects: {'AMSET 2'}));
      controller.setBrowseCategory('مخزن الكهرباء');

      expect(controller.filter.projects, {'AMSET 2'});
      expect(controller.filter.categories, {'مخزن الكهرباء'});
      expect(controller.visibleItems.single.code, 'EL-CB-025');

      controller.setBrowseCategory(null);
      expect(controller.filter.categories, isEmpty);
      expect(controller.filter.projects, {'AMSET 2'});
    });
  });

  test('AlertsCubit filters the preview alerts', () async {
    final cubit = AlertsCubit(repository: const PreviewAlertsRepository());
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.selectStatus(StockStatus.outOfStock);
    expect(cubit.state.items.single.code, 'GS-OX-004');

    await cubit.selectStatus(StockStatus.low);
    expect(cubit.state.items, hasLength(3));
  });

  test('ReportsCubit combines movement type and project filters', () {
    final controller = ReportsCubit(PreviewData.reportMovements);
    addTearDown(controller.close);

    controller.selectType(MovementType.returned);
    expect(controller.visibleMovements.single.itemCode, 'EL-CB-025');

    controller.selectType(null);
    controller.selectProject('ورشة الصيانة');
    expect(controller.visibleMovements.single.itemCode, 'WD-WR-030');
  });

  test('ReportsCubit applies an inclusive custom date range', () {
    final controller = ReportsCubit(PreviewData.reportMovements);
    addTearDown(controller.close);

    controller.selectDateRange(
      DateTimeRange(
        start: DateTime(2026, 8, 10, 20),
        end: DateTime(2026, 8, 13, 1),
      ),
    );

    expect(controller.period, ReportPeriod.custom);
    expect(
      controller.visibleMovements.map((movement) => movement.itemCode),
      containsAll(<String>['EL-CB-025', 'WD-WR-030']),
    );
    expect(controller.visibleMovements, hasLength(2));

    controller.selectPeriod(ReportPeriod.all);
    expect(controller.dateRange, isNull);
    expect(controller.visibleMovements, hasLength(3));
  });
}
