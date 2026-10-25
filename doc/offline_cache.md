# Viewed-page inventory cache

## Implemented: Inventory

`main()` installs `ProductionStartup` from `lib/startup/production_startup.dart`
with `runApp()` before opening Hive CE or initializing Supabase. Flutter displays
a dashboard-shaped Skeletonizer state while Hive opens. If opening or recovering the cache
fails, an Arabic device-storage error screen offers Retry. This is separate
from the no-connection Inventory screen shown when no snapshot is available.
Supabase initialization runs independently with a bounded wait; failures leave
the application shell usable. Missing production configuration and connection
failures have separate failure messages. A null client never selects preview
fixtures in a production repository factory.

The production repository requests one bounded page (20 items by default)
from Supabase and saves its rows in Hive CE. It does not automatically download
all N inventory rows. Scrolling toward the end requests the next server page.
Pulling down requests a fresh first page; an unfiltered pull starts a new saved
generation so deleted items do not linger in the viewed-page cache. Search and
filter changes start a new server query. The count beside the list identifies
displayed items, not an exact total matching count.

If the service fails, the repository searches and filters only saved rows and
uses a `cached:` cursor for local pagination. The Inventory screen explicitly
warns that offline results may be incomplete. Successful live requests remain
usable even if saving a page fails. Viewed pages survive restarts; no full
catalog download runs during startup or in the background.

The saved rows support Arabic-normalized search through
`core/utils/search_normalizer.dart`, category/project/status filters,
deterministic sorting, local offset cursors, and stable
`table_name::item_id` routes. The app remains read-only; there are no offline
mutations, write queues, or conflict handling.

## Recovery states

| State | Inventory behavior |
| --- | --- |
| Viewed pages saved, service unavailable | Show saved items with a partial-coverage warning and last save time. Search and filters run over saved items only. Pull to refresh retries without deleting data. |
| No snapshot, service unavailable | Show the Arabic in-app connection screen with **إعادة المحاولة**. No preview items are inserted. |
| Saved pages, refresh fails | Keep visible items and show a nonblocking stale-data message. |
| Service restored | Retry the first request or pull to refresh. A restart or application-data clear is unnecessary. |

Both Hive adapters read their stored field count once before decoding fields.
The persisted boxes can therefore reopen on later app launches without
discarding saved pages.

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

Each dataset needs its own cache and coverage metadata. Saved inventory pages
alone must not be used to fabricate an offline dashboard,
detail, movement history, alert, or report result.
