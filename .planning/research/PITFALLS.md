# Domain Pitfalls

**Domain:** iOS Fuel Tracker / Mapping
**Researched:** 2024-05-24

## Critical Pitfalls

### Pitfall 1: Map Performance Stutter
**What goes wrong:** UI hangs or stutters during map panning/zooming.
**Why it happens:** Rendering many custom `Annotation` views in SwiftUI or performing heavy price calculations in the `body` of a View.
**Consequences:** App feels unpolished or broken.
**Prevention:** Use `Marker` instead of `Annotation` where possible. Move price logic and RAG calculations to the ViewModel or Background service.
**Detection:** Excessive CPU usage in Xcode Gauges during map interaction.

### Pitfall 2: Excessive Battery Drain
**What goes wrong:** User's battery percentage drops rapidly while the app is in background.
**Why it happens:** Misconfiguring `CLLocationManager` to stay active at high precision indefinitely.
**Consequences:** Negative App Store reviews and uninstallation.
**Prevention:** Use `CLBackgroundActivitySession` carefully. Prefer "Standard Location Service" or "Significant Location Change" over "Continuous Updates" when the app is in background.
**Detection:** Energy Impact gauge in Xcode.

### Pitfall 3: Stale Data / Ghost Stations
**What goes wrong:** User navigates to a station only to find the price is wrong or the station is closed.
**Why it happens:** Relying too heavily on old cache or infrequent API updates.
**Consequences:** Loss of user trust.
**Prevention:** Implement clear timestamps for "Last Updated." Force an API refresh if data is older than 4-6 hours.
**Detection:** Discrepancy reports from users.

## Moderate Pitfalls

### Pitfall 1: SwiftData UI Sync
**What goes wrong:** Map markers don't update when data is refreshed in the background.
**Why it happens:** Background context (via `ModelActor`) saves don't always trigger an immediate refresh of `@Query` if not properly observed.
**Prevention:** Ensure the `@Query` is on the main context or use an `Observable` ViewModel to bridging the data.

### Pitfall 2: Permissions Friction
**What goes wrong:** User denies location permission, rendering the app useless.
**Prevention:** Explain the value of location *before* triggering the system prompt. Provide a "Search by Location" manual option.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| **Core Mapping** | Marker overlap | Use `Marker` system-managed balloons which handle basic overlap/selection better. |
| **Price Data** | API Rate Limits | Implement a local cache (SwiftData) with a TTL (Time-To-Live). |
| **Backgrounding** | Task suspension | Handle the 30s limit of `BGAppRefreshTask` carefully; keep network payloads small. |

## Sources

- [Apple Developer: Core Location Best Practices](https://developer.apple.com/documentation/corelocation/cllocationmanager)
- [StackOverflow: SwiftUI Map performance](https://stackoverflow.com/questions/62908235/swiftui-map-performance)
