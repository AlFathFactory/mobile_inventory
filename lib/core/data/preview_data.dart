import '../../features/dashboard/model/dashboard_models.dart';
import '../../features/inventory/model/inventory_item.dart';
import '../../features/inventory/model/inventory_movement.dart';

abstract final class PreviewData {
  static const items = <InventoryItem>[
    InventoryItem(
      code: 'PA-GN-059',
      name: 'هيمباريم 500 × 16 لتر رال 7032',
      category: 'الدهانات',
      project: 'AMSET 4',
      quantity: 69,
      minimum: 10,
      supplier: 'شركة يوتن مصر',
      expiry: 'مارس 2027',
      notes: 'دفعة مطابقة للمواصفات — تُخزَّن بعيدًا عن الحرارة',
    ),
    InventoryItem(
      code: 'HW-SC-112',
      name: 'مسامير قلاووظ ٦ مم',
      category: 'مسامير',
      project: 'مخزن عام',
      quantity: 8,
      minimum: 20,
    ),
    InventoryItem(
      code: 'GS-OX-004',
      name: 'اسطوانة أكسجين صناعي',
      category: 'اسطوانات',
      project: 'AMSET 4',
      quantity: 0,
      minimum: 3,
    ),
    InventoryItem(
      code: 'WD-WR-030',
      name: 'سلك لحام ٣.٢ مم',
      category: 'مخزن اللحام',
      project: 'ورشة الصيانة',
      quantity: 145,
      minimum: 50,
    ),
    InventoryItem(
      code: 'EL-CB-025',
      name: 'كابل كهرباء ٢.٥ مم',
      category: 'مخزن الكهرباء',
      project: 'AMSET 2',
      quantity: 12,
      minimum: 15,
    ),
    InventoryItem(
      code: 'PA-TH-020',
      name: 'تينر عام ٢٠ لتر',
      category: 'مستهلكات',
      project: 'AMSET 2',
      quantity: 34,
      minimum: 12,
    ),
    InventoryItem(
      code: 'RM-PP-088',
      name: 'أكواع حديد ٢ بوصة',
      category: 'خامات',
      project: 'ورشة الصيانة',
      quantity: 6,
      minimum: 10,
    ),
  ];

  static const catalogCodes = <String>{
    'PA-GN-059',
    'HW-SC-112',
    'GS-OX-004',
    'WD-WR-030',
    'EL-CB-025',
    'PA-TH-020',
  };

  static const alertCodes = <String>{
    'GS-OX-004',
    'HW-SC-112',
    'EL-CB-025',
    'RM-PP-088',
  };

  static List<InventoryItem> get catalogItems => items
      .where((item) => catalogCodes.contains(item.code))
      .toList(growable: false);

  static List<InventoryItem> get alertItems => items
      .where((item) => alertCodes.contains(item.code))
      .toList(growable: false);

  static InventoryItem itemByCode(String code) =>
      items.firstWhere((item) => item.code == code);

  static const dashboardMetrics = <DashboardMetric>[
    DashboardMetric(label: 'إجمالي الأصناف', value: 428),
    DashboardMetric(label: 'مخزون منخفض', value: 14),
    DashboardMetric(label: 'نفد المخزون', value: 3),
  ];

  static const categories = <CategorySummary>[
    CategorySummary(name: 'الدهانات', itemCount: 86, attentionCount: 4),
    CategorySummary(name: 'مسامير', itemCount: 52, attentionCount: 2),
    CategorySummary(name: 'اسطوانات', itemCount: 18, attentionCount: 1),
    CategorySummary(name: 'مخزن الكهرباء', itemCount: 63, attentionCount: 0),
    CategorySummary(name: 'مخزن اللحام', itemCount: 41, attentionCount: 0),
    CategorySummary(name: 'مستهلكات', itemCount: 95, attentionCount: 0),
  ];

  static final movements = <InventoryMovement>[
    InventoryMovement(
      id: 'paint-issue-history',
      itemCode: 'PA-GN-059',
      itemName: 'هيمباريم 500 × 16 لتر رال 7032',
      category: 'الدهانات',
      type: MovementType.issue,
      quantity: 10,
      before: 79,
      after: 69,
      date: DateTime(2026, 8, 11),
      project: 'AMSET 4',
      partyLabel: 'المستلم',
      partyName: 'عمرو فايز',
    ),
    InventoryMovement(
      id: 'paint-addition-history',
      itemCode: 'PA-GN-059',
      itemName: 'هيمباريم 500 × 16 لتر رال 7032',
      category: 'الدهانات',
      type: MovementType.addition,
      quantity: 40,
      before: 39,
      after: 79,
      date: DateTime(2026, 8, 2),
      project: 'AMSET 4',
      partyLabel: 'المورد',
      partyName: 'شركة يوتن مصر',
      purchaseOrder: 'PO-2231',
    ),
    InventoryMovement(
      id: 'paint-return-history',
      itemCode: 'PA-GN-059',
      itemName: 'هيمباريم 500 × 16 لتر رال 7032',
      category: 'الدهانات',
      type: MovementType.returned,
      quantity: 5,
      before: 34,
      after: 39,
      date: DateTime(2026, 7, 28),
      project: 'AMSET 2',
      partyLabel: 'المُرجِع',
      partyName: 'ابانوب عاطف',
    ),
    InventoryMovement(
      id: 'paint-adjustment-history',
      itemCode: 'PA-GN-059',
      itemName: 'هيمباريم 500 × 16 لتر رال 7032',
      category: 'الدهانات',
      type: MovementType.adjustment,
      quantity: -2,
      before: 36,
      after: 34,
      date: DateTime(2026, 7, 15),
      project: 'AMSET 4',
      note: 'تصحيح بعد الجرد الدوري',
    ),
    InventoryMovement(
      id: 'paint-report',
      itemCode: 'PA-GN-059',
      itemName: 'هيمباريم 500 × 16 لتر رال 7032',
      category: 'الدهانات',
      type: MovementType.issue,
      quantity: 10,
      before: 79,
      after: 69,
      date: DateTime(2026, 8, 15),
      project: 'AMSET 4',
      partyLabel: 'المستلم',
      partyName: 'عمرو فايز',
    ),
    InventoryMovement(
      id: 'wire-report',
      itemCode: 'WD-WR-030',
      itemName: 'سلك لحام ٣.٢ مم',
      category: 'مخزن اللحام',
      type: MovementType.addition,
      quantity: 60,
      before: 85,
      after: 145,
      date: DateTime(2026, 8, 13),
      project: 'ورشة الصيانة',
      partyLabel: 'المورد',
      partyName: 'الشرق للتوريدات',
    ),
    InventoryMovement(
      id: 'cable-report',
      itemCode: 'EL-CB-025',
      itemName: 'كابل كهرباء ٢.٥ مم',
      category: 'مخزن الكهرباء',
      type: MovementType.returned,
      quantity: 8,
      before: 4,
      after: 12,
      date: DateTime(2026, 8, 10),
      project: 'AMSET 2',
      partyLabel: 'المُرجِع',
      partyName: 'عبدالرحمن أسامة',
    ),
  ];

  static List<InventoryMovement> movementsFor(String itemCode) => movements
      .where(
        (movement) =>
            movement.itemCode == itemCode && movement.id.endsWith('history'),
      )
      .toList(growable: false);

  static List<InventoryMovement> get reportMovements => movements
      .where((movement) => movement.id.endsWith('report'))
      .toList(growable: false);
}
