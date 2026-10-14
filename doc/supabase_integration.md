# Supabase integration boundary

Inventory, Item Details, Movement History, Alerts, and Dashboard use live
Supabase reads when a client is configured. The remaining features continue
to use `PreviewData` and can move independently behind their repository
contracts.

## Local configuration

Copy `config/supabase.example.json` to `config/supabase.local.json`, then set:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Run with:

```shell
flutter run --dart-define-from-file=config/supabase.local.json
```

Local JSON configuration is ignored by Git. A publishable key is intended for
mobile clients, but database access must still be protected with least-privilege
`SELECT` grants and Row Level Security. Never put a service-role or secret key
in this application or its build configuration.

When no values are supplied, `SupabaseBootstrap` skips client initialization
and the existing PreviewData application starts normally.

## Read-only data flow

```text
View -> Controller -> Repository contract -> PreviewData adapter (fallback)
                                  \-------> Supabase adapter (configured)
                                  \-------> Local cache adapter (future)
```

Repository contracts expose only `fetch` operations. There are no insert,
update, delete, mutation RPC, or storage-write APIs.

`PageRequest.cursor` is deliberately opaque. Current adapters use deterministic
bounded offset tokens and apply filters before querying. Repositories return
`DataResult`, while controllers can map that result to `DataLoadState` for
loading, success, empty, offline/unavailable, and server-error UI behavior.

## Expected row mapping

Existing domain models are reused and provide `fromJson` factories for the
flat, read-oriented rows returned by future tables or security-invoker views:

- `InventoryItem` and derived `StockStatus`
- `InventoryMovement` and `MovementType`
- `DashboardMetric` and `CategorySummary`
- `AlertSummary`
- `ReportSnapshot`

Alert rows reuse `InventoryItem`; report rows reuse `InventoryMovement`. This
avoids DTO copies until the actual database schema proves a transformation is
needed.

## Live Alerts strategy

Alerts read `public.inventory_category_items_summary_view`. The adapter filters
the view's `status` values (`منتهي`, `قليل`) server-side, issues at most two
bounded row queries per page to guarantee out-of-stock-before-low-stock order,
and uses `updated_at`, `table_name`, and `item_id` as deterministic ordering
columns inside each severity segment. Count-only queries provide the existing
summary without downloading inventory rows.

Every live alert retains `table_name` and `item_id`; its detail route is
`table_name::item_id`. No alert repository exposes insert, update, delete,
acknowledgement, RPC-write, or storage-write operations.

## Live Dashboard strategy

Dashboard reads the read-only `get_inventory_dashboard_summary_rpc` RPC for
aggregate metrics (`total_items`, `low_stock`, `out_of_stock`) and category
summaries (`id`/`category_id` when the backend provides one, otherwise the
stable category name). Missing RPC keys map to zero/empty rather than failing,
and rows without a usable category name are skipped.

Attention previews reuse the Alerts segment strategy against
`public.inventory_category_items_summary_view` (out-of-stock first, low-stock
fill, `updated_at`, `table_name`, `item_id` ordering, bounded to the UI limit)
and map through `InventoryItem.fromInventorySummaryRow`, preserving
`table_name::item_id` identity. Recent activity reads a bounded newest-first
slice of `public.inventory_item_movements_view` (`operation_date`,
`created_at`, `id`) via `InventoryMovement.tryFromMovementViewRow`, skipping
unknown operation types. Summary, attention, and recent reads run in parallel;
no safe-row downloads, no N+1 queries, and no dashboard repository exposes
writes of any kind.
