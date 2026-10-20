# Supabase integration boundary

Inventory, Item Details, Movement History, Alerts, Dashboard, and Reports use
live Supabase reads when a client is configured. Without a client, every
feature uses its PreviewData repository.

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
                                  \-------> Hive CE inventory snapshot (configured production inventory)
```

Repository contracts expose only `fetch` operations. There are no insert,
update, delete, mutation RPC, or storage-write APIs.

`PageRequest.cursor` is deliberately opaque. Current adapters use deterministic
bounded offset tokens and apply filters before querying. Repositories return
`DataResult`, while controllers can map that result to `DataLoadState` for
loading, success, empty, offline/unavailable, and server-error UI behavior.

## Inventory Hive CE synchronization

When a Supabase client is configured, `main.dart` initializes Hive CE and
injects `HiveInventoryLocalDataSource` into the inventory repository factory.
Preview mode does not initialize or use this source.

The coordinator requests the inventory summary view in ordered, bounded pages
until the server returns the final short page. It does not rely on a
connectivity indicator: request success is the availability check. A 15-minute
fresh snapshot prevents a new full download on every inventory-screen opening;
manual Inventory refresh forces one.

Hive metadata records the dataset name (`inventory`), cache schema version,
active generation, complete-snapshot flag, in-progress state, last successful
sync timestamp, and last failure type. Inventory records are staged under a
new generation and metadata is committed only after all pages have been stored.
An interrupted generation is never made active, and an existing complete
generation remains readable after a failed refresh. Schema invalidation marks
the snapshot unavailable until a later successful replacement; it does not
erase a known-good generation while the backend is unavailable.

This cache contains only `inventory_category_items_summary_view` rows. The
other Supabase paths below remain live-only until they receive their own
complete, versioned datasets.

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

## Live Reports strategy

The app uses the existing production `public.get_aggregated_inventory_report_rpc`
for the filtered addition and issue summary. Its actual signature is:

```text
get_aggregated_inventory_report_rpc(
  p_from_date date, p_to_date date, p_category_name text,
  p_project_name text, p_search text, p_operation_type text,
  p_page integer, p_page_size integer
) returns jsonb
```

The response has `rows`, `total_items`, and `summary`. The summary contains
`addition_operations_count`, `issue_operations_count`, `total_added_quantity`,
and `total_issued_quantity`. The current timeline UI uses only the two
operation counts. Its total-movements metric comes from a count-only read of
`public.inventory_item_movements_view`, since the RPC's `total_items` counts
distinct inventory items, not movement rows. The RPC's `rows` are aggregated
inventory items (`table_name`, `item_id`, `item_name`, `category_name`,
`project_name`, `code_number`, added and issued quantities, and raw-material
dimensions); they do not represent timeline movements.

Timeline rows come from a bounded selection of
`public.inventory_item_movements_view`. Filters are applied before the read:
`operation_date` inclusive date bounds, `operation_type` (`add`, `issue`,
`return`, `adjust`), `category_name`, `project_name`, and search over displayed
names/codes. Rows use `operation_date DESC, created_at DESC, id DESC` and the
shared `InventoryMovement` mapper. Unknown operation types are skipped.
`table_name` and `item_id` remain attached to the model; their stable detail
identity is `table_name::item_id`. Reports rows currently do not navigate.

The RPC aggregates only `add` and `issue`. When the UI selects `return` or
`adjust`, the corresponding addition/issue summary values are zero and no RPC
is called. For search queries, count-only reads from the movement view provide
the addition/issue values because the RPC uses different Arabic normalization;
this keeps the displayed metrics consistent with the visible search result.
The RPC cannot aggregate return/adjust quantities or return a movement
timeline without a backend change.

`PageRequest` defaults to 20 rows. A page reads at most 21 movement rows and
encodes the next offset in its opaque cursor. Only the first page is loaded
automatically; scrolling requests subsequent pages. The RPC is called with
`p_page=1, p_page_size=1` because only its global filtered summary is used.
Category filter choices are discovered with bounded keyset reads of the
movement view, one distinct name per call; project choices come from the
small `projects` lookup table. The UI date range and Dashboard-to-Reports
navigation remain unchanged. No report path writes to Supabase.

The next backend milestone is a report RPC that returns filtered timeline
rows, all four operation-type counts, category/project options, and an opaque
page cursor in one response. That would remove the separate count and facet
reads while retaining the current UI.
