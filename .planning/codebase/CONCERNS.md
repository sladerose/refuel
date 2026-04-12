# Codebase Concerns

**Analysis Date:** 2026-04-11

## Tech Debt

**God View Pattern:**
- Status: [x] Fixed
- Resolution: Refactored `ContentView.swift` by extracting `HikeAlertBanner`, `RefuelHistoryView`, and `AddRefuelLogView` into separate files. Business logic and service management moved to `ContentViewModel`.
- Files: `refuel/ContentView.swift`, `refuel/ContentViewModel.swift`, `refuel/HikeAlertBanner.swift`, `refuel/HistoryViews.swift`

**Mock Data Dependency:**
- Issue: The app currently relies on `MockFuelPriceService` for all fuel price data. No real API integration exists.
- Files: `refuel/FuelPriceService.swift`, `refuel/ContentView.swift`
- Impact: The app cannot function in a real-world environment without a production API.
- Fix approach: Implement a production version of `FuelPriceService` that connects to a real fuel price API.

**Lack of Error Handling:**
- Issue: Many asynchronous operations use basic `print` statements for error handling instead of user-facing alerts or retry logic.
- Files: `refuel/FuelPriceIngestor.swift`, `refuel/ContentView.swift`, `refuel/OCRService.swift`
- Impact: Poor user experience when things go wrong; errors are silent to the user.
- Fix approach: Implement a robust error handling strategy with user-facing alerts and proper logging.

## Performance Bottlenecks

**Analytics Recalculation:**
- Issue: `calculateAnalytics(for:)` recalculates Z-scores for the entire station database every time prices are updated.
- Files: `refuel/FuelPriceIngestor.swift`
- Cause: Global recalculation logic using `vDSP`.
- Improvement path: Optimize to recalculate only for relevant stations (e.g., within a specific radius) or perform calculations in the background/on a server.

**Battery Consumption:**
- Issue: `LocationManager` uses `kCLLocationAccuracyBest` and `CLLocationUpdate.liveUpdates()` continuously.
- Files: `refuel/LocationManager.swift`
- Cause: Continuous high-accuracy location tracking.
- Improvement path: Implement a more energy-efficient location strategy, using lower accuracy when appropriate and stopping updates when not needed.

## Fragile Areas

**OCR Parsing Logic:**
- Issue: Receipt and price board parsing rely on fragile regex patterns and hardcoded strings for fuel grades.
- Files: `refuel/OCRService.swift`
- Why fragile: Minor variations in receipt formatting or fuel grade naming will cause parsing to fail.
- Safe modification: Use a more robust parsing strategy, perhaps leveraging LLMs for better text extraction or a more comprehensive set of regex patterns.
- Test coverage: Some unit tests exist in `refuelTests/OCRServiceTests.swift`, but they likely don't cover many real-world edge cases.

## Scaling Limits

**Local Analytics:**
- Issue: Performing Z-score calculations locally on the device for a growing number of stations.
- Current capacity: Works for a few dozen stations.
- Limit: Performance will degrade as the number of stations in the SwiftData store increases.
- Scaling path: Move heavy analytics to a backend service and fetch pre-calculated scores.

## Missing Critical Features

**Authentication & Sync:**
- Problem: No user authentication or cloud synchronization. Data is lost if the app is deleted.
- Blocks: Community-driven features like reporting prices and earning rewards across devices.
- Priority: High

**Real-time API Integration:**
- Problem: No connection to a live fuel price data provider.
- Blocks: Real-world utility of the app.
- Priority: High

## Test Coverage Gaps

**Integration Tests:**
- What's not tested: End-to-end flow from location update to price refresh and geofence setup.
- Files: `refuel/ContentView.swift`, `refuel/FuelPriceIngestor.swift`
- Risk: Changes to the refresh logic might break the automatic update mechanism.
- Priority: Medium

---

*Concerns audit: 2026-04-11*
