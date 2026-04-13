# Phase 13: Live Data Ingestion & Alerts - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire `FuelPriceSyncService` to the live Fuel SA API (uncomment the URLSession call, add real auth header), add `BGAppRefreshTask` for background data ingestion, and replace the hardcoded first-Wednesday hike alert logic in `ProactiveService.scheduleHikeAlerts()` with API-driven predictive alerts. Crowdsourced price updates and server-side APNs push are out of scope — local notifications triggered by background refresh only.

</domain>

<decisions>
## Implementation Decisions

### Hike Alert Trigger
- **D-01:** Alert fires when the new API price is **higher** than the value currently stored in SwiftData. Any increase triggers the alert — no minimum threshold.
- **D-02:** Alert is **pre-announcement**: fires before the new price takes effect (i.e., when the API signals an upcoming change, not after it goes live). If the API returns a future `effective_date`, use that to determine timing. If no future date is available, alert immediately on detection.
- **D-03:** Replace `ProactiveService.scheduleHikeAlerts()` hardcoded first-Wednesday scheduling with this data-driven comparison. The background sync result drives the alert — no more calendar-based hardcoding.

### Regional Pricing (Coastal vs Inland)
- **D-04:** User-selectable region in Settings — Coastal or Inland. Stored in `UserDefaults`. No GPS-based auto-detection.
- **D-05:** Default to Coastal if no preference set (larger market: Cape Town, Durban).

### Fuel Grade Preference
- **D-06:** User-selectable preferred fuel grade in Settings — Petrol 95 or Diesel 50ppm. Stored in `UserDefaults`. Alert and displayed benchmark price uses only the user's selected grade.
- **D-07:** Default to Petrol 95 if no preference set.

### API Key Management
- **D-08:** API key lives in a gitignored `.xcconfig` file (e.g. `Secrets.xcconfig`). Injected as a build setting (e.g. `FUEL_SA_API_KEY`), read at runtime via `Bundle.main.infoDictionary["FUEL_SA_API_KEY"]`. The `"YOUR_API_KEY_HERE"` placeholder in `FuelPriceSyncService` is replaced with this bundle lookup.
- **D-09:** This is an **infrastructure-only phase** — the real API key is TBD. Plans must document exactly where to drop the key (which `.xcconfig` entry) so it can be wired in later without code changes.

### BGAppRefreshTask Data Flow
- **D-10:** Background task wakes the app → calls `FuelPriceSyncService.syncLatestPrices()` → compares new price to value stored in SwiftData → if new price > stored price for the user's selected grade/region, fires a local notification via `NotificationManager`.
- **D-11:** **Silent fail** on background refresh error (no network, API down, etc.) — log the error via `OSLog`, reschedule the next `BGAppRefreshTask`, and do nothing else. No user-facing error for background sync failures.
- **D-12:** Hike notification fires **at most once per price cycle** — once an alert has been sent for a given price value, do not re-alert on subsequent syncs until the stored price changes again.

### Claude's Discretion
- `BGAppRefreshTask` identifier naming convention and scheduling interval
- Exact `UserDefaults` key names for region and grade preferences
- Settings UI placement for region/grade pickers (recommend: alongside existing notification settings)
- How to persist "last alerted price" to prevent duplicate notifications (UserDefaults or a SwiftData field on a settings model)
- OSLog category and subsystem names for new background sync logging

</decisions>

<specifics>
## Specific Ideas

- The existing `ProactiveService.nextFirstWednesday()` and `scheduleHikeAlerts()` should be replaced entirely — the new data-driven path makes calendar arithmetic unnecessary.
- `NotificationManager.scheduleLocalNotification()` is the correct delivery mechanism — no new notification infrastructure needed.
- `FuelPriceSyncService` already has the correct `FuelSADTO` shape and `baseURL`. Phase 13 is primarily about uncommenting the real URLSession call and wiring the result through to a notification check.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core sync and ingestion services
- `refuel/FuelPriceSyncService.swift` — existing `@ModelActor actor` with commented-out URLSession, `FuelSADTO`, API key placeholder, and `baseURL`. This is the primary file being completed.
- `refuel/FuelPriceIngestor.swift` — `@ModelActor actor` for updating `Station` SwiftData records and running z-score analytics. `syncLatestPrices()` should call into this after fetching.

### Notification infrastructure
- `refuel/NotificationManager.swift` — `@Observable` class wrapping `UNUserNotificationCenter`. `scheduleLocalNotification()` is the correct delivery path. Deep linking via `stationID` is already supported.
- `refuel/ProactiveService.swift` — contains `scheduleHikeAlerts()` and `nextFirstWednesday()` to be replaced. Also contains dwell/exit notification logic that must be preserved.

### App entry and registration
- `refuel/refuelApp.swift` — `BGTaskScheduler.register()` calls must be added here at app launch.

### Architecture patterns
- `.planning/codebase/ARCHITECTURE.md` — `@ModelActor` pattern for background SwiftData ops, `@Observable` for service layer.
- `.planning/codebase/CONVENTIONS.md` — naming conventions for new files and types.

### CloudKit setup reference (same container, background capability)
- `CLOUDKIT_SETUP.md` — Background Modes capability setup (same Xcode steps needed for BGAppRefreshTask).

No external API spec — Fuel SA API shape is already modelled in `FuelSADTO`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `NotificationManager.scheduleLocalNotification(title:body:identifier:stationID:timeInterval:)` — already handles scheduling, deep link payload, and error logging. Use directly.
- `FuelPriceIngestor.calculateAnalytics(for:)` — static method for z-score recalculation after price update. Call after `syncLatestPrices()` updates SwiftData.
- `ProactiveService` — inject the real sync result here (or restructure so `BGAppRefreshTask` calls `FuelPriceSyncService` directly and then fires the notification check separately).

### Established Patterns
- `@ModelActor` for all background SwiftData operations — `FuelPriceSyncService` and `FuelPriceIngestor` already follow this.
- `@Observable` for services injected into SwiftUI — `NotificationManager`, `ProactiveService`, `ContentViewModel`.
- `OSLog` with `Logger(subsystem:category:)` — all services use this pattern.

### Integration Points
- `refuelApp.swift` — `BGTaskScheduler.register(forTaskWithIdentifier:)` and `BGTaskScheduler.submit()` calls belong here.
- `ContentViewModel.swift` — already holds `NotificationManager` instance and `FuelPriceIngestor` usage; may be the natural place to expose `lastSyncDate` or sync status.
- `Info.plist` — `BGTaskSchedulerPermittedIdentifiers` array must be added for the background task identifier.

</code_context>

<deferred>
## Deferred Ideas

- Server-side APNs push (push from a backend when prices change) — out of scope; Phase 13 uses local notifications only.
- Per-station price alerts (alert when a favourite station's price changes) — REQUIREMENTS.md TRACK-03 is a v2 item.
- Crowdsourced price updates — explicitly out of scope per PROJECT.md.

</deferred>

---

*Phase: 13-live-data-ingestion-alerts*
*Context gathered: 2026-04-13*
