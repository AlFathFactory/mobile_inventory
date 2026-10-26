# Connection recovery

Production data is live-only. Inventory, Dashboard, Alerts, Reports, Item
Details, and Movement History do not offer offline browsing or persist
inventory snapshots. PreviewData is used only by the explicit preview/test app.

`ProductionStartup` renders the app shell while Supabase initializes. A
connection failure from startup or any live repository displays a full-screen
Arabic connection overlay. The overlay blocks interaction with underlying
screens and offers **إعادة المحاولة**. Retry makes a real, bounded inventory
read. When that succeeds, the overlay closes and the app reloads its live
repositories at the current route. A failed retry leaves the overlay visible. Configuration,
authorization, and server errors keep their existing feature-level messages.

The first launch after upgrading from the cache version deletes the old
`cache_metadata_v1` and `inventory_snapshots_v1` Hive files from the app
documents directory, or their IndexedDB databases on web. The cleanup names
only those two boxes; other app data is untouched. Hive is no longer a
dependency or a startup requirement.
