# Supabase integration boundary

The application still runs entirely from `PreviewData`. Supabase startup and
read contracts are present so features can move independently after the remote
schema and read policies are agreed.

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
View -> Controller -> Repository contract -> PreviewData adapter (current)
                                  \-------> Supabase adapter (future)
                                  \-------> Local cache adapter (future)
```

Repository contracts expose only `fetch` operations. There are no insert,
update, delete, mutation RPC, or storage-write APIs.

`PageRequest.cursor` is deliberately opaque. PreviewData uses an offset token;
a future Supabase implementation should use a stable keyset cursor and apply
the contract's filters before its bounded query. Repositories return
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

## Connecting the first live repository

Start with Inventory because it establishes item identity, category IDs,
search, status filtering, and pagination used by Item Details, Alerts, and
Reports. Implement `InventoryRepository` with an injected `SupabaseClient`,
keep `PreviewInventoryRepository` available as the fallback, and switch the
composition root only after SELECT grants, RLS, indexes, and mapping tests are
in place.

Do not query the entire inventory table. Apply a bounded page size and stable
ordering in the Supabase adapter, and keep Supabase-specific exceptions inside
that adapter by converting them to `DataError`.
