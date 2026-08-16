# El Fateh Inventory Monitor

An Arabic, right-to-left Flutter inventory-monitoring prototype for El Fateh's main warehouse. It provides a dashboard, searchable/filterable inventory, low-stock alerts, item details and movement history, and movement reports.

This document is both the project README and the handoff guide for future developers or AI coding models. It describes the code as it exists now; it does not assume a backend or architecture layers that have not yet been implemented.

## Current status

- Flutter application with Material 3 UI.
- Arabic-only UI rendered right-to-left.
- In-memory preview data only; there is no API, database, authentication, repository, or persistence layer yet.
- State is managed with Flutter's built-in `ChangeNotifier` and `ListenableBuilder`.
- Navigation is handled by `go_router` with a state-preserving four-tab shell.
- A simulated 650 ms initial load drives an app-wide skeleton effect.
- Unit/controller tests and widget/navigation tests are included.

## Quick start

Requirements inferred from `pubspec.lock`:

- Flutter `>=3.38.0`
- Dart `>=3.10.8 <4.0.0`

Run the project:

```bash
flutter pub get
flutter run
```

Validate changes:

```bash
dart format lib test
flutter analyze
flutter test
```

## Dependencies

The intentionally small dependency set is declared in `pubspec.yaml`:

| Package | Purpose |
| --- | --- |
| `flutter_localizations` | Arabic Material, Widgets, and Cupertino localization delegates |
| `go_router` | Named routes, nested detail routes, and the stateful bottom-tab shell |
| `skeletonizer` | App-wide skeleton loading effect |
| `cupertino_icons` | Standard icon asset package |
| `flutter_lints` | Analyzer lint baseline used by `analysis_options.yaml` |

## Project structure

```text
el_fateh/
├── assets/
│   └── fonts/                       # IBM Plex Sans Arabic: Light, Medium, Bold
├── lib/
│   ├── main.dart                    # Flutter entry point; runs MyApp
│   ├── app.dart                     # MaterialApp.router, theme, locale, RTL direction
│   ├── core/
│   │   ├── data/
│   │   │   └── preview_data.dart    # All current in-memory demo records
│   │   ├── router/
│   │   │   ├── app_router.dart      # Controllers, route graph, view wiring, disposal
│   │   │   ├── app_routes.dart      # Central route names and top-level paths
│   │   │   ├── app_shell.dart       # Tab shell, bottom navigation, skeleton wrapper
│   │   │   └── not_found_view.dart  # Invalid route/item fallback
│   │   ├── theme/
│   │   │   ├── app_colors.dart      # Application color tokens
│   │   │   ├── app_text_styles.dart # Named typography tokens
│   │   │   ├── app_theme.dart       # Material ThemeData and component defaults
│   │   │   └── status_visuals.dart  # Stock/movement enum-to-label/color mappings
│   │   └── widgets/                  # Reusable cross-feature UI components
│   ├── features/
│   │   ├── dashboard/
│   │   ├── inventory/
│   │   ├── alerts/
│   │   └── reports/
│   └── Inventory Monitor (standalone).html
│                                        # Bundled visual reference; not used at runtime
├── test/
│   ├── controllers_test.dart            # Model and controller behavior
│   └── widget_test.dart                 # RTL, tabs, filters, routes, loading, layouts
├── pubspec.yaml
└── analysis_options.yaml
```

The generated Android, iOS, web, Windows, macOS, and Linux folders contain normal Flutter platform scaffolding. Business and UI work should normally happen under `lib/`.

## Runtime architecture

The app uses a lightweight feature-first architecture:

```text
main()
  -> MyApp
     -> AppTheme.light
     -> AppRouter
        -> creates long-lived controllers from PreviewData
        -> configures GoRouter
        -> injects data/controllers/callbacks into feature views
           -> views listen to controllers
           -> feature widgets render models with core design components
```

### Startup and lifetime

1. `main.dart` calls `runApp(const MyApp())`.
2. `MyApp` creates one `AppRouter` for the widget's lifetime.
3. `AppRouter` creates `InventoryController`, `AlertsController`, and `ReportsController` directly. There is no service locator or dependency-injection package.
4. Controllers receive subsets of `PreviewData` and remain alive while the app is alive.
5. `AppRouter` starts `InventoryController.loadPreviewData()`. Its loading flag is also used by `AppShell` to skeletonize every tab.
6. When `MyApp` is disposed, `AppRouter.dispose()` disposes the router and all three controllers.

This ownership is important: do not create a new controller inside a feature view on every build. Router-level controller lifetime is why search/filter state survives tab changes.

### State and UI communication

The established communication loop is:

```text
user event
  -> view calls a controller method
  -> controller mutates private state and calls notifyListeners()
  -> ListenableBuilder rebuilds the affected view
  -> derived getters provide the filtered display list
```

- Controllers expose immutable source lists and derived getters rather than public mutable state.
- Views receive controllers and navigation callbacks through constructors.
- Small, temporary widget-only state can use `setState`; the inventory filter sheet does this for its uncommitted draft.
- Navigation belongs primarily in `AppRouter`. Views use callbacks when crossing features. The item-details view calls a named nested route directly for its own history page.
- Dashboard has no controller because its current metrics and lists are static inputs with no local mutation.

### Dependency direction as implemented

This codebase is feature-first, but `core` is not a completely feature-independent domain layer:

- `dashboard` reuses inventory's `InventoryItem` and `InventoryItemCard`.
- `alerts` reuses inventory's item model and item card.
- `reports` reuses inventory's movement model and `MovementCard`.
- `core/theme/status_visuals.dart` maps inventory enums to shared visuals.
- `core/widgets/status_badge.dart` displays inventory `StockStatus`.
- `core/data/preview_data.dart` constructs dashboard and inventory feature models.
- `core/router/app_router.dart` is the composition root and therefore imports all routed features.

Preserve these real relationships unless a task explicitly asks for a larger domain/data-layer refactor. Avoid creating circular imports between feature folders.

## Routing and screen flow

`AppRouter` uses `StatefulShellRoute.indexedStack`, which keeps the navigation and widget state of all four branches alive.

| Tab | Name | Path | View |
| --- | --- | --- | --- |
| Dashboard | `dashboard` | `/` | `DashboardView` |
| Inventory | `inventory` | `/inventory` | `InventoryView` |
| Alerts | `alerts` | `/alerts` | `AlertsView` |
| Reports | `reports` | `/reports` | `ReportsView` |

Inventory also owns two nested full-screen routes:

| Name | Effective path | View |
| --- | --- | --- |
| `item-details` | `/inventory/:code` | `ItemDetailsView` |
| `item-history` | `/inventory/:code/history` | `MovementHistoryView` |

Both nested routes use `rootNavigatorKey`, so they open above the tab shell rather than inside the inventory branch. Unknown item codes and unknown routes render `NotFoundView`.

Cross-screen behavior:

- Dashboard “show all” clears inventory filters, then switches to Inventory.
- Tapping a dashboard category applies that inventory category filter, then switches tabs.
- Dashboard notification action switches to Alerts.
- Dashboard, Inventory, and Alerts item cards all use the same router callback to push item details.
- Item Details pushes the item's complete preview movement history.

Add every reusable route name/path to `app_routes.dart`; do not scatter literal paths through widgets.

## Core folder

### `core/data`

`PreviewData` is the only data source today. It contains:

- Seven sample inventory records.
- Six records exposed through `catalogItems`.
- Four low/out-of-stock records exposed through `alertItems`.
- Dashboard summary/category samples.
- Item-history and report movement samples distinguished by ID suffix.
- Helpers for item lookup and per-item movement lookup.

Important limitations:

- Dashboard totals (`428`, `14`, `3`), alert totals (`14`, `3`), and report totals (`128`, `74`, `39`) are presentation samples, not calculated from the small record lists.
- Reports use a fixed preview date of `2026-08-16` to make “last 30 days” deterministic.
- Loading is simulated; records already exist in memory while the skeleton is visible.

When a real backend is added, introduce explicit data-source/repository boundaries and asynchronous error/empty/loading states. Do not quietly mix network calls into widgets.

### `core/theme`

Use the design tokens instead of hard-coded styling in feature files.

- `AppColors`: background/surface/text colors, cyan accent scale, neutral scale, stock-status colors, return color, divider, and shadow.
- `AppTextStyles`: `pageTitle`, `sectionTitle`, `cardTitle`, `body`, `label`, `caption`, `number`, and `code`.
- `AppTheme.light`: Material 3 theme, text theme mapping, app bar, inputs, chips, bottom sheets, and Skeletonizer configuration.
- `StockStatusVisuals` and `MovementTypeVisuals`: Arabic labels plus foreground/background colors for domain enums.

Typography uses `IBMPlexSansArabic`, registered in `pubspec.yaml` with weights 300, 500, and 700. Inventory codes are deliberately wrapped with LTR `Directionality` even though the application is RTL. Preserve that treatment for other Latin identifiers, SKUs, order numbers, and mixed-direction values.

### `core/widgets`

`app_components.dart` is the barrel export used by feature views. It exports the common components except `AppBottomNavigation`, which is shell-specific.

| Widget | Responsibility |
| --- | --- |
| `ResponsivePage` | Centers content, limits width to 600 px, and applies standard page padding |
| `AppCard` | Shared bordered/elevated surface with optional tap handling |
| `PageHeader` | Page title with an optional circular action icon |
| `SectionHeader` | Section title and optional text action |
| `SummaryCard` | Small label/value metric card |
| `StatusBadge` | Stock status pill using enum visual extensions |
| `FilterChipBar<T>` | Horizontally scrollable single-choice filter row |
| `FilterChipOption<T>` | Typed value/label object for `FilterChipBar` |
| `AppDropdown<T>` | Consistently styled generic dropdown |
| `KeyValueRow` | Detail label/value row |
| `EmptyState` | Shared empty/not-found presentation |
| `AppBottomNavigation` | Four navigation destinations in shell branch order |

Prefer composing these widgets before creating a feature-local duplicate. Put a widget in `core/widgets` only when it is genuinely useful across features; otherwise keep it in that feature's `widgets` folder.

## Feature folders

Each feature generally follows this structure:

```text
feature_name/
├── controller/   # ChangeNotifier and feature state/filter logic
├── model/        # Immutable data and filter/snapshot types
├── view/         # Route-level screens
└── widgets/      # UI used within the feature (or intentionally shared)
```

Not every feature needs every layer. Do not add empty folders or a controller for static screens.

### Dashboard

- `DashboardView` receives all data and actions from `AppRouter`.
- `DashboardMetric` and `CategorySummary` are immutable display models.
- `CategorySummaryCard` renders category navigation cards.
- `dashboard_cards.dart` contains `StockHealthCard`, but its use is currently commented out in `DashboardView`.
- It reuses inventory item cards for the “needs attention” list.

### Inventory

Inventory is the central domain feature and supplies models/widgets to other features.

- `InventoryItem` derives `StockStatus`: quantity `<= 0` is out of stock; quantity below minimum is low; otherwise safe.
- `InventoryMovement` captures movement type, quantity transition, date, project, party, order, and note metadata.
- `InventoryFilter` holds multi-select statuses, categories, and projects and reports its selection count.
- `InventoryController` owns search text, quick status, advanced filters, preview loading, source items, and derived `visibleItems`.
- `InventoryView` owns only its `TextEditingController`; its value is initialized from the long-lived inventory controller.
- `InventoryFilterSheet` edits local draft sets and commits only when Apply is pressed.
- `InventoryItemCard` is reused by Dashboard and Alerts.
- `MovementCard` and `QuantityTransition` are reused by Item Details, History, and Reports.

All inventory filters combine with logical AND. Values inside one multi-select group combine with logical OR. `clearFilters()` preserves search by default; pass `includeQuery: true` to clear it too.

### Alerts

- `AlertsController` receives the preview alert subset and filters it by one optional `StockStatus`.
- `AlertSummary` holds display totals.
- `AlertsView` listens to the controller, renders filter chips, and reuses `InventoryItemCard`.
- `AlertOverview` renders the low/out-of-stock summary cards.

The alert summary counts are currently fixed preview totals and intentionally larger than the sample list.

### Reports

- `ReportsController` filters preview movements by period, movement type, project, and category.
- `ReportPeriod` and `ReportSnapshot` define filter and summary display data.
- `ReportFilters` combines generic dropdowns with a movement-type chip bar.
- `ReportsView` listens to the controller and reuses inventory's `MovementCard`.

Report filters also combine with logical AND. A null movement type/project/category means “all.”

## Localization and layout rules

- The application locale is fixed to Arabic with `Locale('ar')`.
- `MyApp.builder` enforces `TextDirection.rtl` for the entire widget tree.
- User-facing copy is currently written directly in Arabic; there are no ARB files or generated localization keys.
- Save Dart/Markdown files as UTF-8. Some Windows console configurations may display Arabic as mojibake even when the source file is valid; inspect/read explicitly as UTF-8 before changing text.
- Use `EdgeInsetsDirectional` when start/end semantics matter.
- Use `ResponsivePage` for route content and account for its 600 px maximum width.
- Existing widget tests cover 320×568, 392×812, and 600×1024 layouts.

## Testing strategy

`test/controllers_test.dart` verifies:

- Derived stock status.
- Arabic-name and Latin-code inventory search.
- Combined advanced filters.
- Quick status and dashboard category filtering.
- Alert status filtering.
- Report movement/project filtering.

`test/widget_test.dart` verifies:

- Arabic RTL rendering and all four tabs.
- Inventory search persistence across tabs.
- Advanced inventory filter sheet behavior.
- Named item-details and movement-history routes.
- Initial skeleton loading.
- No layout exceptions at three common viewport sizes.

When behavior changes, update or add the narrowest relevant controller test and then cover important user flows with a widget test. `MyApp(previewLoadDelay: Duration.zero)` makes most widget tests deterministic; use the default delay only when testing the skeleton.

## How to add or change a feature

1. Read the relevant feature's model, controller, view, and widgets together.
2. Reuse `AppColors`, `AppTextStyles`, `AppTheme`, and `core/widgets` rather than duplicating visual values.
3. Put persistent mutable screen state in a controller and expose derived getters.
4. Keep uncommitted, short-lived form or sheet drafts local to the widget.
5. Construct long-lived dependencies at the composition root (`AppRouter` today).
6. Add route names and paths centrally, then wire the screen in the appropriate shell branch.
7. Preserve branch order in both `AppRouter` and `AppBottomNavigation`.
8. Add representative preview data if the real source is not implemented.
9. Add tests for controller rules, routing/state preservation, and narrow layouts.
10. Format, analyze, and run the full test suite.

If implementing a backend, first decide and document the new data/repository boundary, loading/error contracts, and how controllers receive dependencies. Keep `PreviewData` usable as a test fixture or replace it deliberately; do not leave production and preview sources ambiguously mixed.

## AI continuation guide

For any future AI model working on this repository:

1. Treat this README and the source code as the architectural source of truth; verify details in code before editing.
2. Start with `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/core/router/app_router.dart`, and the complete target feature.
3. Inspect `app_colors.dart`, `app_text_styles.dart`, `app_theme.dart`, `status_visuals.dart`, and `app_components.dart` before adding UI.
4. Check `PreviewData` and both test files to understand fixtures and protected behavior.
5. Do not claim the app has a backend, dependency-injection framework, generated localization, or persistent storage—it currently does not.
6. Preserve Arabic RTL behavior and force Latin identifiers to LTR where needed.
7. Preserve controller/router lifetimes so state continues to survive tab switches.
8. Avoid broad refactors unless requested. The cross-feature inventory reuse described above is intentional in the current code.
9. Do not edit generated build output or platform folders for ordinary Dart/UI tasks.
10. Validate with formatting, analysis, and tests, and report any command that could not be run.

## Known cleanup opportunities

These are observations, not required changes:

- Move hard-coded Arabic strings to Flutter localization resources when multiple locales or translation workflows are needed.
- Introduce repositories/data sources when a real API or database is selected.
- Derive summaries from real data instead of fixed preview totals.
- Replace the fixed report preview date with an injected clock when reports become live.
- Consider moving shared inventory domain types to a neutral domain package only if cross-feature coupling grows.
- Rename `CategorySummaryCard.dart` to the Dart-standard `category_summary_card.dart` and update its import.
- Remove commented-out UI blocks after the design direction is finalized.
- Move the standalone HTML design artifact outside `lib/` if it remains documentation-only.
