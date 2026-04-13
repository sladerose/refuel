# Phase 13: Live Data Ingestion & Alerts - Research

**Researched:** 2026-04-13
**Domain:** iOS Background Tasks (BGAppRefreshTask), URLSession API integration, UserDefaults preferences, local notifications
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Alert fires when new API price is **higher** than SwiftData stored value. No minimum threshold — any increase triggers.
- **D-02:** Alert is **pre-announcement**: fires before new price takes effect. If API returns a future `effective_date`, use it for timing. If no future date, alert immediately on detection.
- **D-03:** Replace `ProactiveService.scheduleHikeAlerts()` and `nextFirstWednesday()` with data-driven comparison. Background sync result drives the alert.
- **D-04:** User-selectable region (Coastal / Inland) in Settings. Stored in `UserDefaults`. No GPS-based auto-detection.
- **D-05:** Default to Coastal if no preference set.
- **D-06:** User-selectable preferred fuel grade (Petrol 95 / Diesel 50ppm) in Settings. Stored in `UserDefaults`. Alert and benchmark price use only the user's selected grade.
- **D-07:** Default to Petrol 95 if no preference set.
- **D-08:** API key lives in a gitignored `.xcconfig` file (`Secrets.xcconfig`). Injected as a build setting (`FUEL_SA_API_KEY`), read at runtime via `Bundle.main.infoDictionary["FUEL_SA_API_KEY"]`.
- **D-09:** Infrastructure-only phase — real API key is TBD. Plans must document exactly where to drop the key so it can be wired in later without code changes.
- **D-10:** Background task wake → `FuelPriceSyncService.syncLatestPrices()` → compare new price to SwiftData stored value → if new price > stored price for user's selected grade/region → fire local notification via `NotificationManager`.
- **D-11:** Silent fail on background refresh error — log via `OSLog`, reschedule next `BGAppRefreshTask`, do nothing else.
- **D-12:** Hike notification fires at most once per price cycle — do not re-alert until stored price changes again.

### Claude's Discretion

- `BGAppRefreshTask` identifier naming convention and scheduling interval
- Exact `UserDefaults` key names for region and grade preferences
- Settings UI placement for region/grade pickers (recommend: alongside existing notification settings)
- How to persist "last alerted price" to prevent duplicate notifications (UserDefaults or a SwiftData field on a settings model)
- OSLog category and subsystem names for new background sync logging

### Deferred Ideas (OUT OF SCOPE)

- Server-side APNs push (push from a backend when prices change)
- Per-station price alerts (TRACK-03 is a v2 item)
- Crowdsourced price updates
</user_constraints>

---

## Summary

Phase 13 wires three systems together: live API data ingestion via URLSession, periodic background wakeups via `BGAppRefreshTask`, and data-driven local notifications replacing the hardcoded Wednesday calendar logic. The existing codebase has all the foundational pieces — `FuelPriceSyncService` has the correct DTO shape and a commented-out URLSession call, `NotificationManager` has the correct delivery API, and `ProactiveService` has the scheduling infrastructure that needs replacement.

The two technically novel areas are (1) correctly integrating `BGAppRefreshTask` into the SwiftUI app lifecycle using the `.backgroundTask` scene modifier (preferred for Swift 6 apps), and (2) safely threading the `ModelContainer` into the background task closure so `FuelPriceSyncService` (a `@ModelActor`) can access SwiftData without triggering Swift concurrency violations. `ModelContainer` is `Sendable`, so it can be passed across isolation boundaries. All other new code (UserDefaults preference storage, last-alerted price guard, Settings UI rows) is straightforward and matches existing patterns in the project.

The API key injection uses the standard xcconfig → build setting → Info.plist route. Because the project uses `GENERATE_INFOPLIST_FILE = YES`, the `BGTaskSchedulerPermittedIdentifiers` array key cannot be injected via a simple `INFOPLIST_KEY_` build setting — it must be added via Xcode's Info tab on the target (which writes it into `project.pbxproj`) or by switching to a static Info.plist. The Xcode Info tab approach is the least disruptive.

**Primary recommendation:** Use the SwiftUI `.backgroundTask(.appRefresh(...))` scene modifier on `WindowGroup` in `refuelApp.swift`. Capture `Self.sharedModelContainer` in the closure (it is `Sendable`), instantiate `FuelPriceSyncService` inside the closure, call `syncLatestPrices()`, and pipe the result into a notification check. Keep `NotificationManager` calls on a `@MainActor` path via `Task { @MainActor in ... }` within the background closure.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| BackgroundTasks framework | iOS 13+ / built-in | `BGAppRefreshTask` and `BGTaskScheduler` | Apple-native; no alternatives on iOS |
| UserNotifications framework | iOS 10+ / built-in | Local notification delivery | Already in use via `NotificationManager` |
| URLSession | Swift / built-in | HTTP API call in `FuelPriceSyncService` | Already stubbed; just needs uncommenting |
| Foundation `UserDefaults` | Built-in | Persisting region, grade, and last-alerted price | Matches existing project pattern for lightweight prefs |
| OSLog | Built-in | Background sync error logging | Already used project-wide (D-11 requirement) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Swift Testing (`@Test`) | Xcode 16 / built-in | Unit tests for sync/comparison logic | All new logic tests; project already uses this framework |
| Foundation `JSONDecoder` | Built-in | Decoding `FuelSADTO` from API response | Already used in service layer |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `.backgroundTask` SwiftUI modifier | `BGTaskScheduler.shared.register(...)` in `application(_:didFinishLaunchingWithOptions:)` | Legacy UIKit pattern; SwiftUI modifier is the Swift 6 idiomatic approach and cleaner |
| `UserDefaults` for last-alerted price | SwiftData field on a settings model | UserDefaults is simpler and sufficient for a single scalar value; no model migration needed |

**Installation:** No new packages. All frameworks are built-in.

---

## Architecture Patterns

### Recommended Project Structure

No new files required for the core logic. New file for Settings UI rows:

```
refuel/
├── FuelPriceSyncService.swift    # PRIMARY: uncomment URLSession, add xcconfig key lookup
├── ProactiveService.swift        # Refactor: remove scheduleHikeAlerts/nextFirstWednesday
├── NotificationManager.swift     # Unchanged — use existing scheduleLocalNotification
├── refuelApp.swift               # Add BGTaskScheduler register + .backgroundTask modifier
├── ProfileView.swift             # Add Settings section rows for region + grade pickers
└── Secrets.xcconfig              # NEW (gitignored): FUEL_SA_API_KEY = YOUR_API_KEY_HERE
```

### Pattern 1: SwiftUI Scene `backgroundTask` Modifier (preferred for Swift 6)

**What:** Attach `.backgroundTask(.appRefresh("identifier"))` to the `WindowGroup` scene. The system calls the async closure when the app wakes for the registered task. Inside, schedule the next task and do the work.

**When to use:** Any time you need `BGAppRefreshTask` in a SwiftUI app lifecycle (iOS 16+). Replaces the `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)` pattern.

**Example:**
```swift
// Source: WWDC22 "Efficiency awaits: Background tasks in SwiftUI"
// https://developer.apple.com/videos/play/wwdc2022/10142/
@main
struct refuelApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: Self.sharedModelContainer)
        }
        .modelContainer(Self.sharedModelContainer)
        .backgroundTask(.appRefresh("com.slade.refuel.price-sync")) {
            // ModelContainer is Sendable — safe to capture
            let container = Self.sharedModelContainer
            let syncService = FuelPriceSyncService(modelContainer: container)
            do {
                try await syncService.syncLatestPrices()
            } catch {
                // D-11: silent fail — OSLog only
                Logger(subsystem: "com.slade.refuel", category: "BackgroundSync")
                    .error("Background sync failed: \(error)")
            }
            // Reschedule for next interval
            scheduleNextPriceSync()
        }
    }
}
```

**Scheduling when entering background:**
```swift
// Source: https://www.peppe.app/how-to-use-backgroundtask-in-swiftui/
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .background {
        scheduleNextPriceSync()
    }
}

func scheduleNextPriceSync() {
    let request = BGAppRefreshTaskRequest(identifier: "com.slade.refuel.price-sync")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min minimum
    try? BGTaskScheduler.shared.submit(request)
}
```

### Pattern 2: ModelActor Instantiation in Background Closures

**What:** `@ModelActor` actors receive the `ModelContainer` in their initializer. `ModelContainer` is `Sendable`, so it crosses actor boundaries safely. The `ModelContext` lives inside the actor and never crosses boundaries.

**When to use:** Any time you need SwiftData access inside a background task or non-main-actor context.

**Critical pitfall:** If a `@ModelActor` is instantiated on the main thread, it silently executes on the main thread — defeating its purpose. Instantiate inside the `.backgroundTask` closure (which is off the main actor by default) to guarantee background execution. [CITED: massicotte.org/model-actor/]

**Example:**
```swift
// Source: https://useyourloaf.com/blog/swiftdata-background-tasks/
// ModelContainer is Sendable — pass it; never pass ModelContext
let syncService = FuelPriceSyncService(modelContainer: container)
try await syncService.syncLatestPrices()
```

### Pattern 3: UserDefaults for Preference Storage

**What:** Store region and grade preferences as raw strings. Use computed properties with defaults for safe access.

**Example:**
```swift
// ASSUMED — consistent with project UserDefaults usage elsewhere
extension UserDefaults {
    var preferredRegion: String {
        get { string(forKey: "refuel.preferredRegion") ?? "coastal" }
        set { set(newValue, forKey: "refuel.preferredRegion") }
    }
    var preferredGrade: String {
        get { string(forKey: "refuel.preferredGrade") ?? "petrol95" }
        set { set(newValue, forKey: "refuel.preferredGrade") }
    }
    var lastAlertedPrice: Double {
        get { double(forKey: "refuel.lastAlertedPrice") }
        set { set(newValue, forKey: "refuel.lastAlertedPrice") }
    }
}
```

### Pattern 4: xcconfig API Key Injection

**What:** A gitignored `Secrets.xcconfig` defines `FUEL_SA_API_KEY = your_key_here`. The build setting is surfaced in the generated Info.plist, then read at runtime via `Bundle.main`.

**How (step by step):**
1. Create `Secrets.xcconfig` at project root. Add to `.gitignore`.
2. In Xcode: Project → Info → Configurations → Debug → assign `Secrets.xcconfig` to the `refuel` target.
3. In `Secrets.xcconfig`: `FUEL_SA_API_KEY = YOUR_API_KEY_HERE`
4. In target Build Settings: add `INFOPLIST_KEY_FUEL_SA_API_KEY = $(FUEL_SA_API_KEY)` (or add `FUEL_SA_API_KEY = $(FUEL_SA_API_KEY)` under Other Linker Flags and reference in Info.plist additions).
5. Alternative: add `FUEL_SA_API_KEY` entry to the target's Info tab (Xcode Target → Info → Custom iOS Target Properties).
6. In `FuelPriceSyncService.swift`: `Bundle.main.infoDictionary?["FUEL_SA_API_KEY"] as? String ?? ""`

[CITED: enjelhutasoit.com/2025/08/retrieve-api-keys-from-xcconfig-files.html]

### Anti-Patterns to Avoid

- **Hardcoding the API key in source code.** The existing `"YOUR_API_KEY_HERE"` literal must be replaced with the bundle lookup. Source files are committed; the xcconfig is not.
- **Instantiating FuelPriceSyncService (or any @ModelActor) on the main thread then passing it to background work.** Create the actor inside the `.backgroundTask` closure.
- **Passing `ModelContext` or `Station` model objects across actor boundaries.** Pass `ModelContainer` (Sendable) or `PersistentIdentifier` only.
- **Registering `BGTaskScheduler.shared.register(...)` after app launch completes.** Registration must happen during app initialization, before any task can be delivered. With the `.backgroundTask` modifier, SwiftUI handles this automatically.
- **Omitting `BGTaskSchedulerPermittedIdentifiers` from Info.plist.** The task identifier in code must exactly match an entry in this array or the system will never deliver the task.
- **Suppressing the INFOPLIST_KEY_ scalar limit.** `BGTaskSchedulerPermittedIdentifiers` is an array key — it cannot be injected via a simple `INFOPLIST_KEY_*` build setting under `GENERATE_INFOPLIST_FILE = YES`. It must be added via the Xcode Info tab (Target → Info → Custom iOS Target Properties → add `BGTaskSchedulerPermittedIdentifiers` array).
- **Not rescheduling inside the background task handler.** `BGAppRefreshTask` is one-shot. Fail to call `BGTaskScheduler.shared.submit()` inside the handler and the task never runs again.
- **Calling `task.setTaskCompleted(success:)` before awaiting async work.** The system terminates the process immediately after `setTaskCompleted` — the `.backgroundTask` modifier handles this automatically (the task completes when the closure returns).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Periodic background wakeup | Custom polling timer / `DispatchQueue.asyncAfter` | `BGAppRefreshTask` + `BGTaskScheduler` | System-managed wakeup survives app termination; custom timers do not |
| Local notification delivery | UNUserNotificationCenter directly | `NotificationManager.scheduleLocalNotification(...)` | Already handles scheduling, deep link payload, error logging, and delegate setup |
| Thread-safe SwiftData access | Manual `ModelContext` synchronization | `@ModelActor` pattern already in codebase | Compiler-enforced isolation; existing actors (`FuelPriceSyncService`, `FuelPriceIngestor`) already follow this |
| JSON decoding of API response | Custom parser | `JSONDecoder().decode(FuelSADTO.self, from:)` | `FuelSADTO` and `FuelPricesData` are already modelled with correct coding keys |

**Key insight:** The entire notification delivery, SwiftData access, and JSON parsing infrastructure already exists. Phase 13 is primarily wiring — uncomment the URLSession call, add the comparison check, register the background task.

---

## Common Pitfalls

### Pitfall 1: BGTaskSchedulerPermittedIdentifiers Array Not Declared

**What goes wrong:** App builds and runs, but `BGTaskScheduler.shared.submit()` silently returns an error (`BGTaskScheduler.Error.notPermitted`). Tasks are never delivered.

**Why it happens:** `BGTaskSchedulerPermittedIdentifiers` is an array key. Under `GENERATE_INFOPLIST_FILE = YES`, it cannot be set via `INFOPLIST_KEY_*` build settings (which only handle scalar values). Developers familiar with scalar keys assume the same approach works for arrays.

**How to avoid:** Add `BGTaskSchedulerPermittedIdentifiers` explicitly via Xcode Target → Info tab → Custom iOS Target Properties. Type: Array, Value: `com.slade.refuel.price-sync` (must exactly match the identifier used in code).

**Warning signs:** No crash or explicit error in console; tasks simply never fire. Test using the Xcode debugger simulate command (see Validation section).

### Pitfall 2: Background Capability Not Enabled

**What goes wrong:** Same symptom as Pitfall 1 — tasks never fire.

**Why it happens:** `BGAppRefreshTask` requires the "Background fetch" mode in the Background Modes capability. Without it, `BGTaskSchedulerPermittedIdentifiers` alone is insufficient.

**How to avoid:** Target → Signing & Capabilities → + Capability → Background Modes → check "Background fetch". This is a separate Xcode step from adding the Info.plist key.

**Warning signs:** App Store Connect upload warning: "Missing Info.plist value. The key `BGTaskSchedulerPermittedIdentifiers` must contain a list of identifiers used to submit and handle tasks when `UIBackgroundModes` has a value of `fetch`."

### Pitfall 3: ModelActor Initialized on Main Thread

**What goes wrong:** `FuelPriceSyncService` operations block the main thread or produce incorrect isolation. In Swift 6 strict concurrency mode, you may get unexpected actor-context crashes.

**Why it happens:** `@ModelActor` is context-sensitive: if initialized on the main thread, it runs on the main thread. The `.backgroundTask` closure is off-main by default, but if `FuelPriceSyncService` is initialized in a `@MainActor` context first and reused, it executes on the wrong thread. [CITED: massicotte.org/model-actor/]

**How to avoid:** Always instantiate `FuelPriceSyncService` fresh inside the `.backgroundTask` closure. Do not store it as a property on a `@MainActor` class and pass it in.

**Warning signs:** Main thread checker violations, or SwiftData access warnings in the console during background wakeup.

### Pitfall 4: Duplicate Hike Alerts on Subsequent Syncs

**What goes wrong:** If the API returns the same higher price on two consecutive background wakes, the user receives a second (identical) notification.

**Why it happens:** Without persisting "last alerted price", every sync that finds `newPrice > storedPrice` will fire.

**How to avoid (D-12):** After firing an alert, persist the alerted price value (e.g., `UserDefaults.standard.lastAlertedPrice = newPrice`). On the next sync: only alert if `newPrice > storedPrice && newPrice != lastAlertedPrice`. Reset `lastAlertedPrice` when the stored price changes downward or is updated.

**Warning signs:** User receives duplicate notifications for the same price event.

### Pitfall 5: Notification Without Authorization Check

**What goes wrong:** `NotificationManager.scheduleLocalNotification(...)` silently fails if the user has not granted notification permission. No error is surfaced.

**Why it happens:** `UNUserNotificationCenter.add(_:)` fails silently when not authorized.

**How to avoid:** Check `notificationManager.isAuthorized` before scheduling the hike alert in the background task. If not authorized, log and skip — the user opted out.

**Warning signs:** No notification arrives despite correct price comparison logic. Add a debug `OSLog` statement confirming the notification call was made.

### Pitfall 6: ProactiveService Dwell/Exit Logic Broken by Refactor

**What goes wrong:** When removing `scheduleHikeAlerts()` and `nextFirstWednesday()` from `ProactiveService`, the dwell timer logic and exit notification logic (which must be preserved) are accidentally deleted or broken.

**Why it happens:** Both the to-be-deleted calendar logic and the to-be-preserved geofence logic live in the same `ProactiveService.swift` file.

**How to avoid:** Remove only `scheduleHikeAlerts()`, `nextFirstWednesday()`, and `isHikeImminent` from `ProactiveService`. Preserve `startListening()`, `handleEntry()`, `handleExit()`, `triggerDwellNotification()`, and `dwellTimers`. Also remove the `scheduleHikeAlerts()` call from `init`. Update `HikeAlertBanner.swift` — it currently calls `proactiveService.nextFirstWednesday()` which will be deleted.

**Warning signs:** Geofence/dwell notifications stop working after Phase 13.

---

## Code Examples

### Uncommented URLSession Call (FuelPriceSyncService)
```swift
// Source: existing commented-out code in FuelPriceSyncService.swift
func syncLatestPrices() async throws {
    guard let apiKey = Bundle.main.infoDictionary?["FUEL_SA_API_KEY"] as? String,
          !apiKey.isEmpty else {
        throw FuelSyncError.missingAPIKey
    }
    var request = URLRequest(url: URL(string: baseURL)!)
    request.addValue(apiKey, forHTTPHeaderField: "key")
    let (data, _) = try await URLSession.shared.data(for: request)
    let dto = try JSONDecoder().decode(FuelSADTO.self, from: data)
    // Map dto to SwiftData, then run analytics
    try await applyPriceUpdate(dto)
    try modelContext.save()
}
```

### Price Comparison and Alert Gate (new method on FuelPriceSyncService or standalone helper)
```swift
// ASSUMED — consistent with D-10, D-12 logic
func checkAndAlertIfHike(dto: FuelSADTO) {
    let region = UserDefaults.standard.preferredRegion
    let grade = UserDefaults.standard.preferredGrade

    let newPrice: Double
    switch (grade, region) {
    case ("petrol95", "coastal"):   newPrice = dto.data.petrol95_coastal
    case ("petrol95", "inland"):    newPrice = dto.data.petrol95_inland
    case ("diesel50", "coastal"):   newPrice = dto.data.diesel50ppm_coastal
    case ("diesel50", "inland"):    newPrice = dto.data.diesel50ppm_inland
    default:                         newPrice = dto.data.petrol95_coastal
    }

    let storedPrice = UserDefaults.standard.lastAlertedPrice
    guard newPrice > storedPrice else { return }  // D-01: any increase triggers
    guard newPrice != storedPrice else { return }  // D-12: no duplicate

    UserDefaults.standard.lastAlertedPrice = newPrice

    // Fire notification on main actor (NotificationManager is @Observable on main)
    Task { @MainActor in
        notificationManager.scheduleLocalNotification(
            title: "Fuel Price Hike Alert",
            body: "Prices are rising. Fill up now to save!",
            identifier: "hike_alert_\(Int(newPrice * 100))",
            timeInterval: 1
        )
    }
}
```

### BGAppRefreshTask Registration in refuelApp.swift
```swift
// Source: https://developer.apple.com/videos/play/wwdc2022/10142/
.backgroundTask(.appRefresh("com.slade.refuel.price-sync")) {
    let container = Self.sharedModelContainer
    let syncService = FuelPriceSyncService(modelContainer: container)
    let logger = Logger(subsystem: "com.slade.refuel", category: "BGSync")
    do {
        try await syncService.syncLatestPrices()
    } catch {
        logger.error("Background price sync failed: \(error.localizedDescription)")
    }
    // Always reschedule (D-11)
    let req = BGAppRefreshTaskRequest(identifier: "com.slade.refuel.price-sync")
    req.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    try? BGTaskScheduler.shared.submit(req)
}
```

### Xcode Debugger Commands for Testing Background Tasks
```
// Launch the task (run in Xcode debugger console while app is backgrounded):
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.slade.refuel.price-sync"]

// Simulate early expiration:
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.slade.refuel.price-sync"]
```
[CITED: https://uynguyen.github.io/2020/09/26/Best-practice-iOS-background-processing-Background-App-Refresh-Task/]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `BGTaskScheduler.shared.register(...)` in AppDelegate | `.backgroundTask` SwiftUI scene modifier | WWDC22 / iOS 16 | Cleaner lifecycle integration; async/await native |
| Static `Info.plist` file | `GENERATE_INFOPLIST_FILE = YES` with `INFOPLIST_KEY_*` build settings | Xcode 13+ | Array keys (like `BGTaskSchedulerPermittedIdentifiers`) still require Xcode Info tab |
| Calendar-based hike schedule (`nextFirstWednesday`) | Data-driven comparison from API response | Phase 13 | Alerts reflect actual price data, not a hardcoded calendar assumption |

**Deprecated/outdated in this phase:**
- `ProactiveService.scheduleHikeAlerts()`: Replace with BGAppRefreshTask-driven notification.
- `ProactiveService.nextFirstWednesday()`: Remove entirely (no longer needed).
- `ProactiveService.isHikeImminent`: Remove (computed from `nextFirstWednesday`).
- `HikeAlertBanner.swift` reference to `proactiveService.nextFirstWednesday()`: Must be updated or the banner must be driven from the stored price comparison result instead.
- `FuelPriceSyncService` hardcoded `"YOUR_API_KEY_HERE"`: Replace with `Bundle.main.infoDictionary?["FUEL_SA_API_KEY"]` lookup.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `UserDefaults` keys `refuel.preferredRegion`, `refuel.preferredGrade`, `refuel.lastAlertedPrice` don't conflict with any existing keys | Code Examples | Key collision could corrupt stored values; low risk given naming prefix |
| A2 | The Fuel SA API (`api.fuelsa.co.za`) uses a single `key` HTTP header for auth (consistent with the commented-out code) | Code Examples | If the real API uses a different header name or auth scheme, the URLSession call needs adjustment |
| A3 | Scheduling interval of 15 minutes minimum is appropriate for fuel price data (prices change at most once a month) | Architecture Patterns | System may not honor 15-min interval anyway; BGAppRefreshTask frequency is system-discretionary |
| A4 | `HikeAlertBanner` usage of `proactiveService.nextFirstWednesday()` can be replaced by a stored Bool/timestamp from the price comparison result | State of the Art | If the banner's display logic is more complex, the update may be non-trivial |
| A5 | `NotificationManager` instance is accessible inside the `.backgroundTask` closure (via `@MainActor in` task) | Code Examples | If `NotificationManager` has stricter isolation requirements, the call path may need adjustment |

---

## Open Questions

1. **Does `api.fuelsa.co.za` return an `effective_date` field in the response (D-02)?**
   - What we know: `FuelSADTO` only has `last_updated` — no `effective_date` field is modelled.
   - What's unclear: Whether the real API returns a future effective date, or only the current price.
   - Recommendation: Plan as "alert immediately on detection" (D-02 fallback). If API does return an effective date, `FuelSADTO` will need a new optional field and the notification `timeInterval` will be calculated from it.

2. **Should `lastAlertedPrice` be persisted in UserDefaults or as a SwiftData model?**
   - What we know: CONTEXT.md marks this as Claude's discretion.
   - What's unclear: If price history is needed later, SwiftData would be better.
   - Recommendation: Use `UserDefaults` for Phase 13 (single scalar value, no history needed, simpler to access from background context without a ModelContext).

3. **Where exactly does the Settings UI for region/grade pickers live?**
   - What we know: `ProfileView.swift` has an existing `Section("Settings")`. CONTEXT.md suggests placing alongside existing notification settings.
   - What's unclear: Whether the settings section warrants a dedicated `SettingsView` file or rows inline in `ProfileView`.
   - Recommendation: Add rows directly to the existing `Section("Settings")` in `ProfileView` to minimize scope. No new file needed.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | All build/run tasks | ✓ | Xcode 26.4 | — |
| BackgroundTasks framework | BGAppRefreshTask | ✓ | Built into iOS 13+ | — |
| Physical iOS device | BGTask simulation | Required for live testing | iOS 18+ | Xcode debugger simulate command |
| Fuel SA API key | `syncLatestPrices()` live call | ✗ (TBD per D-09) | — | App remains on mock data; key dropped later without code changes |
| `Secrets.xcconfig` | API key injection | ✗ (must be created) | — | Placeholder value keeps build green |

**Missing dependencies with no fallback:**
- A physical iOS device is needed to test `BGAppRefreshTask` delivery (simulators have unreliable background task support). [ASSUMED]

**Missing dependencies with fallback:**
- Fuel SA API key: Placeholder value in `Secrets.xcconfig` keeps the app building. The `syncLatestPrices()` path will throw `FuelSyncError.missingAPIKey` (or return mock data) until the real key is provided.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (import Testing) |
| Config file | Xcode scheme (no external config file) |
| Quick run command | `xcodebuild test -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:refuelTests 2>&1 | tail -20` |
| Full suite command | `xcodebuild test -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30` |

### Phase Requirements → Test Map

| Behavior | Test Type | Notes |
|----------|-----------|-------|
| Price comparison: newPrice > storedPrice triggers alert | Unit | Can be tested in isolation as a pure function |
| Duplicate alert guard (D-12): same price does not re-fire | Unit | Test with same value written twice to UserDefaults |
| Region/grade selection defaults (D-05, D-07) | Unit | Test `UserDefaults` extension property defaults |
| `FuelSADTO` decodes correctly from JSON | Unit | Already implicitly covered; add explicit test |
| BGAppRefreshTask delivery and execution | Manual / Device | Not automatable in CI; use Xcode debugger simulate command |
| Notification fires in foreground (banner appears) | Manual / Device | UNUserNotificationCenter requires real device or simulator with notifications enabled |

### Wave 0 Gaps

- [ ] `refuelTests/FuelPriceSyncTests.swift` — unit tests for price comparison logic and duplicate-alert guard
- [ ] `refuelTests/PreferenceDefaultsTests.swift` — tests for UserDefaults extension property defaults

*(Existing test infrastructure `ValueAnalyticsTests.swift` pattern can be reused — `@MainActor` struct, in-memory `ModelContainer`)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | API key is not a user authentication credential |
| V3 Session Management | No | No session state |
| V4 Access Control | No | No user-facing access control |
| V5 Input Validation | Yes | Decode `FuelSADTO` via `JSONDecoder` with typed fields; invalid JSON throws, caught by D-11 silent fail |
| V6 Cryptography | No | No cryptographic operations |
| V7 Error Handling | Yes | D-11: all background errors logged via OSLog, not surfaced to user |
| V9 Communications | Yes | URLSession uses HTTPS by default; `baseURL` already uses `https://` |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| API key in source control | Information Disclosure | gitignored `.xcconfig`; never commit key in Swift source |
| API key in bundle (Info.plist) | Information Disclosure | Accepted risk per D-08/D-09; key is for a read-only public data API, not a privileged operation |
| Malformed API JSON response | Tampering | `JSONDecoder` with `FuelSADTO` typed struct rejects unexpected shapes |
| Notification spam (duplicate alerts) | Spoofing (user trust) | D-12 last-alerted-price guard prevents re-notification |

---

## Sources

### Primary (HIGH confidence)
- Apple WWDC22 "Efficiency awaits: Background tasks in SwiftUI" — `.backgroundTask` modifier pattern, scheduling, async/await integration
- [BGAppRefreshTask Apple Developer Docs](https://developer.apple.com/documentation/backgroundtasks/bgapprefreshtask) — class overview, time limit (30s), capability requirement
- [BackgroundTask SwiftUI API](https://developer.apple.com/documentation/SwiftUI/BackgroundTask) — `.backgroundTask(.appRefresh(...))` usage
- [massicotte.org/model-actor](https://www.massicotte.org/model-actor/) — ModelActor initialization context pitfall and factory method pattern
- [useyourloaf.com/blog/swiftdata-background-tasks/](https://useyourloaf.com/blog/swiftdata-background-tasks/) — ModelContainer sendability, background task + SwiftData pattern
- Existing codebase: `FuelPriceSyncService.swift`, `FuelPriceIngestor.swift`, `NotificationManager.swift`, `ProactiveService.swift`, `refuelApp.swift`, `project.pbxproj`

### Secondary (MEDIUM confidence)
- [peppe.app/how-to-use-backgroundtask-in-swiftui](https://www.peppe.app/how-to-use-backgroundtask-in-swiftui/) — full BGAppRefreshTask setup walkthrough verified against Apple docs
- [swiftwithmajid.com/2022/07/06/background-tasks-in-swiftui](https://swiftwithmajid.com/2022/07/06/background-tasks-in-swiftui/) — scenePhase monitoring pattern
- [enjelhutasoit.com: Retrieve API Keys from xcconfig](https://www.enjelhutasoit.com/2025/08/retrieve-api-keys-from-xcconfig-files.html) — xcconfig → Info.plist → Bundle.main pattern
- [uynguyen.github.io: BGAppRefreshTask debugger testing](https://uynguyen.github.io/2020/09/26/Best-practice-iOS-background-processing-Background-App-Refresh-Task/) — `_simulateLaunchForTaskWithIdentifier` debugger commands

### Tertiary (LOW confidence — training data)
- UserDefaults extension pattern for typed preference keys
- `scheduleHikeAlerts()` call site in `ProactiveService.init()` — verified by reading source

---

## Metadata

**Confidence breakdown:**
- BGAppRefreshTask setup: HIGH — confirmed via multiple official/community sources
- ModelActor + background task threading: HIGH — confirmed via massicotte.org pitfall analysis + Apple docs
- xcconfig API key injection: MEDIUM — confirmed pattern; exact Xcode steps for `GENERATE_INFOPLIST_FILE = YES` project not explicitly verified in a single authoritative source
- ProactiveService refactor scope: HIGH — verified by reading source files directly
- UserDefaults key naming and defaults: LOW (A1) — conventional approach consistent with project style

**Research date:** 2026-04-13
**Valid until:** 2026-07-13 (stable Apple frameworks; xcconfig patterns don't change frequently)
