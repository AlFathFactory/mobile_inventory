import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/features/alerts/controller/alerts_controller.dart';
import 'package:el_fateh/features/inventory/controller/inventory_controller.dart';
import 'package:el_fateh/features/inventory/model/inventory_filter.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:el_fateh/features/inventory/model/inventory_movement.dart';
import 'package:el_fateh/features/reports/controller/reports_controller.dart';
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

  group('InventoryController', () {
    late InventoryController controller;

    setUp(() {
      controller = InventoryController(
        items: PreviewData.catalogItems,
        initiallyLoading: false,
      );
    });

    tearDown(() => controller.dispose());

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

      controller.filterByCategory('الدهانات');
      expect(controller.quickStatus, isNull);
      expect(controller.visibleItems.single.code, 'PA-GN-059');
    });
  });

  test('AlertsController filters the preview alerts', () {
    final controller = AlertsController(PreviewData.alertItems);
    addTearDown(controller.dispose);

    controller.selectStatus(StockStatus.outOfStock);
    expect(controller.visibleItems.single.code, 'GS-OX-004');

    controller.selectStatus(StockStatus.low);
    expect(controller.visibleItems, hasLength(3));
  });

  test('ReportsController combines movement type and project filters', () {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    controller.selectType(MovementType.returned);
    expect(controller.visibleMovements.single.itemCode, 'EL-CB-025');

    controller.selectType(null);
    controller.selectProject('ورشة الصيانة');
    expect(controller.visibleMovements.single.itemCode, 'WD-WR-030');
  });

  test('ReportsController applies an inclusive custom date range', () {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

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
