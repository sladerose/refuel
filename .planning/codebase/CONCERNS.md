# Codebase Concerns

**Analysis Date:** 2026-04-12

## Tech Debt

**Entire app uses hardcoded MockFuelPriceService:**
- Issue: `MockFuelPriceService` is instantiated directly in `refreshPrices()` inside `ContentView`. There is no real API client. The mock returns a fixed set of 3 stations regardless of location.
- Files: `refuel/ContentView.swift` (line 174), `refuel/FuelPriceService.swift`
- Impact: The app cannot show real-world fuel prices. All RAG analysis, geofencing, and gamification operates on fake data. This is the largest single gap between current state and a shippable product.
- Fix approach: Implement a concrete `FuelPriceService` conformer that calls a real API (e.g., GasBuddy, PetrolSpy, or a custom backend). Inject via the existing protocol so no other call sites change.

**`globalImpactTotal` is a hardcoded fake metric:**
- Issue: `GamificationManager.globalImpactTotal` returns `1420560.0 + Double(count * 15)` — a seeded baseline with no server source.
- Files: `refuel/GamificationManager.swift` (lines 67-72)
- Impact: The "Global Community Savings" number shown in `ProfileView` is fabricated. It will never reflect real community activity and erodes trust if users notice it is always the same base figure.
- Fix approach: Fetch from a backend endpoint or remove the global metric until a server exists.

**`ContentView` is overloaded:**
- Issue: `ContentView.swift` (496 lines) contains: the root view, `HikeAlertBanner`, `RefuelHistoryView`, `AddRefuelLogView`, and the `UUID: Identifiable` extension — all in one file.
- Files: `refuel/ContentView.swift`
- Impact: Hard to navigate, test, or modify any single concern in isolation. `AddRefuelLogView` is particularly large (120+ lines) and would benefit from its own file.
- Fix approach: Extract `RefuelHistoryView`, `AddRefuelLogView`, and `HikeAlertBanner` into separate files under `refuel/`.

**`NavigationServiceTests` contains no assertions:**
- Issue: `NavigationServiceTests.testAppleMapsURL()` has a comment acknowledging the test is not implemented, but the test still passes (vacuously).
- Files: `refuelTests/NavigationServiceTests.swift` (lines 13-19)
- Impact: Gives false confidence. URL construction logic in `NavigationService` is entirely untested.
- Fix approach: Inject a `URLOpener` protocol into `NavigationService` and assert the constructed URL string in tests.

**`refuelTests.refuelTests.example()` is a placeholder:**
- Issue: The default generated test stub with no assertions.
- Files: `refuelTests/refuelTests.swift`
- Impact: Dead weight. Misleads coverage metrics.
- Fix approach: Delete or replace with a meaningful smoke test.

**`Models.o` binary artifact committed to the repo:**
- Issue: A compiled object file (`Models.o`) exists at the repo root and is not listed in `.gitignore`.
- Files: `/Models.o` (repo root)
- Impact: Bloats repo history; should never be in version control.
- Fix approach: Add `*.o` to `.gitignore` and remove the file with `git rm --cached Models.o`.

---

## Known Bugs

**`AddRefuelLogView` calls `gamificationManager` without an `@Environment` declaration — will crash at runtime:**
- Symptoms: App crashes when saving a refuel log (either manual entry or after OCR scan), because `gamificationManager` is referenced as an unresolved identifier inside `AddRefuelLogView`.
- Files: `refuel/ContentView.swift` (lines 464, 467) — `AddRefuelLogView.saveLog()`
- Trigger: Tap "Save" in `AddRefuelLogView` after adding or scanning a refuel event.
- Workaround: None. The view needs `@Environment(GamificationManager.self) private var gamificationManager` added to its property list, matching the `.environment(gamificationManager)` modifier set on the `TabView` in `ContentView`.

**OCR date parser contains a malformed format string:**
- Symptoms: Dates on receipts in `DD/MM/YYYY` format silently fail to parse.
- Files: `refuel/OCRService.swift` (line 132) — `extractDate(from:)`
- Trigger: `"dd/MM/dd/yyyy"` is listed as a format. This is not a valid `DateFormatter` pattern (it has `dd` in the year position). The correct pattern should be `"dd/MM/yyyy"`.
- Workaround: Dates may still parse from the `DD-MM-YYYY` variant, but slash-delimited dates will fail.

**`ContentView.init` creates two `GeofenceService` instances:**
- Symptoms: One `GeofenceService` is created via `@State private var geofenceService = GeofenceService()` at property declaration (line 16) and a second is created explicitly inside `init` (line 31) and assigned over it. The first instance is discarded but briefly starts a `CLLocationManager`.
- Files: `refuel/ContentView.swift` (lines 16, 31-36)
- Trigger: Every cold launch.
- Workaround: The second instance wins and is used correctly, but the redundant `CLLocationManager` initialization wastes resources and may cause brief spurious delegate callbacks.

**Search result card shows `item.name` twice:**
- Symptoms: In `MapView`, the search result chip displays `item.name ?? "Unknown"` as the headline and `item.name ?? ""` as the caption — the same value shown in both positions.
- Files: `refuel/MapView.swift` (lines 147-152)
- Trigger: Any map search that returns results.
- Workaround: The app does not crash, but the UX is confusing. The caption should show `item.placemark.title` or a formatted address instead.

**`ProactiveService` dwell `Timer` is scheduled on a non-main thread:**
- Symptoms: `Timer.scheduledTimer` in `handleEntry(region:)` is called from a `Task` that is not guaranteed to be on the main run loop, so the timer may silently never fire.
- Files: `refuel/ProactiveService.swift` (line 43)
- Trigger: User enters a geofenced station region.
- Workaround: Wrap the timer creation in `DispatchQueue.main.async` or use a `Task { @MainActor in ... }`.

---

## Security Considerations

**No input validation on OCR-derived prices before persisting:**
- Risk: An adversarial (or simply dirty) image could produce implausible price values (e.g., `999.99` or `0.00`) that are written directly into the SwiftData store and affect the RAG z-score for all stations.
- Files: `refuel/OCRService.swift`, `refuel/PriceVerificationView.swift` (lines 88-111)
- Current mitigation: `PriceVerificationView` lets users review detected prices before saving, but the "Update" button does not validate that prices are within a plausible range.
- Recommendations: Add a sanity check — e.g., reject prices outside `[0.5, 10.0]` per litre — before persisting. Surface an error to the user rather than silently saving garbage data.

**`requestAlwaysAuthorization` requested without background mode justification:**
- Risk: Requesting "Always" location permission is scrutinised by App Store reviewers. Without a registered background mode (`UIBackgroundModes`) the permission request may be rejected or downgraded to "While In Use" silently.
- Files: `refuel/LocationManager.swift` (line 26)
- Current mitigation: None detected.
- Recommendations: Audit `Info.plist` / build settings for `NSLocationAlwaysAndWhenInUseUsageDescription` and relevant background modes. Consider requesting `whenInUse` first and upgrading only if geofencing is confirmed active.

---

## Performance Bottlenecks

**Map renders every station as a custom `Annotation` with nested `Button` views:**
- Problem: `MapView` uses `Annotation` with a multi-layer `VStack` (price label + pump icon + favorite badge) for each station. SwiftUI custom annotations are rendered as `UIView` overlays and do not benefit from MapKit's native clustering or dequeue optimisation.
- Files: `refuel/MapView.swift` (lines 26-79)
- Cause: Each annotation body is a full SwiftUI view hierarchy rebuilt on every map interaction.
- Improvement path: At 20+ stations this will cause visible stutter during pan/zoom. Replace inner views with `Marker` for simple cases, or adopt `MKMapView` with `MKAnnotationView` dequeue if performance degrades. The research document (`PITFALLS.md`) already flags this risk.

**`StationListView.sortedStations` re-creates `CLLocation` objects on every SwiftUI render:**
- Problem: The distance sort in `sortedStations` constructs a `CLLocation` for every station on every view re-render. With a list of 50+ stations and frequent `userLocation` updates, this is an O(n) allocation per frame.
- Files: `refuel/StationListView.swift` (lines 39-44)
- Cause: Computed property with no memoisation, triggered by `@Observable` location changes.
- Improvement path: Cache distances in an intermediate `@State` dictionary keyed by station ID; refresh only when `userLocation` changes by more than a meaningful threshold (e.g., 50 m).

**`OCRService.process` mixes `DispatchGroup` with unstructured `DispatchQueue.global` dispatches:**
- Problem: The OCR processing loop dispatches each image to `DispatchQueue.global` inside a `DispatchGroup`, but the `VNImageRequestHandler.perform` call is synchronous and blocking. If many images are submitted simultaneously, this saturates the global queue.
- Files: `refuel/OCRService.swift` (lines 28-58)
- Cause: Legacy GCD pattern in an otherwise Swift Concurrency codebase.
- Improvement path: Refactor `process` as an `async` function using `withCheckedContinuation` or `TaskGroup`, consistent with the rest of the codebase.

---

## Fragile Areas

**`FuelPriceIngestor.calculateAnalytics` is a `static` method called from multiple contexts on `@Model` objects:**
- Files: `refuel/FuelPriceIngestor.swift` (line 60), called from `refuel/ContentView.swift` (line 484), `refuel/PriceVerificationView.swift` (line 106)
- Why fragile: `@Model` objects must be accessed on their originating `ModelContext`. The static method receives `[Station]` from different contexts (actor context in `FuelPriceIngestor`, main context in views). SwiftData does not guarantee thread-safety across contexts; this is a latent data-race.
- Safe modification: Make the method non-static and call it only from within the `FuelPriceIngestor` actor, or guard all call sites with `@MainActor`.
- Test coverage: `ValueAnalyticsTests` covers the calculation logic but uses an in-memory container and does not exercise cross-context access.

**`GamificationManager.fetchOrCreateProfile` is marked `@MainActor` but called from a non-`@MainActor` `init`:**
- Files: `refuel/GamificationManager.swift` (lines 10-30)
- Why fragile: `fetchOrCreateProfile()` performs SwiftData I/O and is marked `@MainActor`, but it is called synchronously from `init` which has no actor isolation. In Swift 6 strict concurrency checking this will produce a warning or error. The call may silently dispatch asynchronously, meaning `userProfile` is `nil` briefly after init.
- Safe modification: Change the call to `Task { @MainActor in fetchOrCreateProfile() }` and handle the brief `nil` state gracefully in all consumers (most already handle it via `if let profile = gamificationManager.userProfile`).

**`ProactiveService.scheduleHikeAlerts` hard-codes South African "first Wednesday of the month" price hike:**
- Files: `refuel/ProactiveService.swift` (lines 94-107)
- Why fragile: The hike alert logic is market-specific (South African petrol board pricing cycle) and undocumented. If the app is ever used in a different market, or the SA pricing cycle changes, the feature silently misfires.
- Safe modification: Move hike schedule configuration to a market-settings struct. Document the SA-specific assumption explicitly.

---

## Scaling Limits

**CLLocationManager geofence region limit (20 regions):**
- Current capacity: `GeofenceService.monitorStation` registers one region per station. `ContentView.refreshPrices` registers a region for every station in the SwiftData store after each refresh.
- Limit: iOS allows a maximum of 20 simultaneously monitored `CLCircularRegion` regions per app. With 3 mock stations + 1 search region the current total is 4. If the real API returns 20+ nearby stations this limit will be silently exceeded; regions beyond the cap are ignored by CoreLocation with no error.
- Scaling path: Prioritise monitoring for the N closest stations (e.g., top 15) and the current search region. Drop monitoring for distant stations after refresh.

**SwiftData schema has no migration strategy:**
- Current capacity: The `Schema` is defined inline in `refuelApp.swift` with no versioned schema or migration plan.
- Limit: Any additive model change (new property, new relationship) in a future release will cause a `ModelContainer` creation failure on devices that have existing data, hitting the `fatalError` at `refuelApp.swift` line 26.
- Scaling path: Adopt `VersionedSchema` and `SchemaMigrationPlan` before the first public release.

---

## Dependencies at Risk

**No external package dependencies — no risk, but also no capability:**
- Risk: The app relies entirely on Apple frameworks. This is intentionally minimal, but means there is no charting library, no networking client with retry/back-off, no crash reporting, and no analytics. Adding any of these later will require SPM integration and review.
- Impact: Acceptable for a pre-release product, but plan the integration before App Store submission.

---

## Missing Critical Features

**No real fuel price data source:**
- Problem: The `FuelPriceService` protocol is defined but only `MockFuelPriceService` exists. No API client is implemented.
- Blocks: All user-facing value propositions (price comparison, RAG status, savings calculations) operate on fiction until a real service is wired in.

**No error UI for failed price refresh:**
- Problem: `ContentView.refreshPrices` catches errors with `print("Failed to refresh prices: \(error)")` and silently discards them.
- Files: `refuel/ContentView.swift` (lines 194-196)
- Blocks: Users have no feedback when the price data fails to load. The app shows stale or empty data with no explanation.

**No error UI for failed OCR scan:**
- Problem: Both `RefuelHistoryView` and `StationDetailView` handle `ReceiptScannerView` failures with `print("Scanner failed: \(error)")`.
- Files: `refuel/ContentView.swift` (line 344), `refuel/StationDetailView.swift` (line 187)
- Blocks: Camera permission denial or scan failures are invisible to the user.

**No location denial recovery flow:**
- Problem: When location is denied, the app shows a "Grant Permission" button, but tapping it calls `requestPermission()` which triggers `requestAlwaysAuthorization()`. On iOS, if permission was previously denied, this call is a no-op — the system does not re-show the prompt. There is no deep link to Settings.
- Files: `refuel/ContentView.swift` (lines 139-158), `refuel/LocationManager.swift` (line 26)
- Blocks: Users who deny then change their mind are stuck on the permission wall with no path to recovery.
- Fix: On denied/restricted status, show a button that opens `UIApplication.openSettingsURLString` instead.

---

## Test Coverage Gaps

**No tests for `GamificationManager` XP awarding or streak logic:**
- What's not tested: XP accumulation, streak increment/reset, lottery entry creation, the 10-day grace period.
- Files: `refuel/GamificationManager.swift`
- Risk: A streak-related regression would go undetected. The grace period boundary (exactly 10 days) is particularly easy to break.
- Priority: High — streak is a primary engagement mechanic.

**No tests for `ProactiveService` dwell/exit logic:**
- What's not tested: Dwell timer fire, "forget to scan" notification scheduling, hike alert date calculation edge cases (e.g., first Wednesday = first day of month).
- Files: `refuel/ProactiveService.swift`
- Risk: Silent regressions in notification timing that users experience as annoying or absent prompts.
- Priority: Medium.

**No tests for `OCRService.parsePriceBoard`:**
- What's not tested: The price board parser (`parsePriceBoard`) has no coverage. Only `parseText` (receipt parsing) is tested in `OCRServiceTests`.
- Files: `refuel/OCRService.swift` (lines 153-181)
- Risk: Price board scan — a key differentiating feature — could silently produce wrong grades or prices.
- Priority: High.

**`NavigationServiceTests` has no assertions (see Tech Debt):**
- What's not tested: URL construction for Apple Maps and Google Maps navigation.
- Files: `refuelTests/NavigationServiceTests.swift`
- Risk: A URL scheme typo would only be caught manually.
- Priority: Low.

**Zero UI tests:**
- What's not tested: The `refuelUITests` target contains only the Xcode boilerplate launch test. No user flows are exercised.
- Files: `refuelUITests/refuelUITests.swift`
- Risk: Any breaking layout regression, missing environment injection, or navigation deadlock requires manual testing to find.
- Priority: Medium — at minimum, a happy-path smoke test through Map → Station Detail → Navigate should exist.

---

*Concerns audit: 2026-04-12*
