# Offline-first inventory cache

## Implemented: Inventory

`main()` installs `ProductionStartup` with `runApp()` before opening Hive CE or
initializing Supabase. Flutter displays a local loading state while Hive opens.
If opening or recovering the cache fails, an Arabic error screen offers Retry.
Supabase initialization runs independently with a bounded wait; failures leave
the application shell usable. Missing production configuration and connection
failures have separate failure messages. A null client never selects preview
fixtures in a production repository factory.

The production inventory repository reads the last complete Hive CE snapshot
first. It filters and sorts the snapshot, then returns only the requested page
(20 items by default). A stale snapshot is displayed while a bounded, ordered,
server-paginated Supabase download prepares a replacement. The replacement is
committed as a new generation only when every requested page has succeeded.

On a cold cache, the first page is fetched through the existing server-side
query and shown immediately. The full snapshot starts in the background after
that page succeeds; the unfiltered first page is reused by the sync when
possible. A sync failure cannot remove the usable first page or an older
committed snapshot. Only one automatic sync starts per repository instance.

The Inventory screen uses an explicit **عرض المزيد** action for subsequent
pages, with a spinner and retry on a failed page. Search and filter changes
reset the cursor. The count beside the list identifies displayed items; the
service currently does not provide an exact total matching count.

The cached inventory supports the current list behavior: Arabic-normalized
search through `core/utils/search_normalizer.dart`, category/project/status
filters, deterministic sorting, local offset cursors, and stable
`table_name::item_id` routes. The app remains read-only; there are no offline
mutations, write queues, or conflict handling.

## Recovery states

| State | Inventory behavior |
| --- | --- |
| Saved snapshot, service unavailable | Show saved pages, a cache banner and last successful sync time. Search and filters continue locally. Refresh retries without deleting data. |
| No snapshot, service unavailable | Show the Arabic in-app connection screen with **إعادة المحاولة**. No preview items are inserted. |
| Saved snapshot, refresh fails | Keep the visible list and show a nonblocking stale-data message. |
| Service restored | Retry the first request or force Refresh. A restart or application-data clear is unnecessary. |

Dashboard, Alerts, Reports, Item Details, and Movement History still require
their own remote data. Their failures remain within their feature routes. The
Inventory cache does not fabricate their results.

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
