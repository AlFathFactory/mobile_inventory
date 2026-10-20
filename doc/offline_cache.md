# Offline cache scope

## Implemented: Inventory

The production inventory repository reads a complete Hive CE snapshot whenever
one is available. A stale snapshot is displayed while a bounded, ordered,
server-paginated Supabase download prepares a replacement. The replacement is
committed as a new generation only when every requested page has succeeded.

The cached inventory supports the current list behavior: Arabic-normalized
search through `core/utils/search_normalizer.dart`, category/project/status
filters, deterministic sorting, local offset cursors, and stable
`table_name::item_id` routes. The app remains read-only; there are no offline
mutations, write queues, or conflict handling.

## Planned datasets

| Feature | Required cache before offline support can be claimed |
| --- | --- |
| Item Details | Full category-specific detail rows, including paint production dates, by stable item identity |
| Movement History | Movement view pages indexed by `table_name::item_id`, with page and date ordering metadata |
| Dashboard | The actual summary RPC result, attention segment, and recent movement slice used by the dashboard |
| Alerts | Alert summary counts and severity-ordered item segments |
| Reports | Aggregated RPC output, selected filters, category/project options, counts, and timeline pages |

Each dataset needs its own completeness metadata and versioned snapshot. An
inventory snapshot alone must not be used to fabricate an offline dashboard,
detail, movement history, alert, or report result.
