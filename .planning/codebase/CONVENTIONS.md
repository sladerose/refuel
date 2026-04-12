# Conventions

Conventions observed and enforced across the Refuel codebase.

---

## Swift Style

- **Swift 6.0** strict concurrency is the baseline. All `@Observable` classes and `@ModelActor` actors must satisfy the compiler's actor-isolation rules without suppressions.
- File headers use the Xcode default comment block (`//\n// Filename.swift\n// refuel\n//`) where auto-generated; new files authored by tooling (e.g., GSD) append a `Created by GSD` byline.
- Imports are grouped: Apple system frameworks first, then any project-local modules. No blank lines between imports within a group; one blank line between groups.
- `final` is applied to every class that is not explicitly designed for subclassing.
- Trailing closures are always used when the closure is the last argument and the call reads naturally without the argument label.

---

## Naming

| Concept | Convention | Example |
|---|---|---|
| SwiftData model | `final class`, `@Model`, UpperCamelCase noun | `Station`, `FuelPrice`, `RefuelEvent` |
| Observable service | `final class`, `@Observable`, noun + role suffix | `LocationManager`, `GeofenceService`, `GamificationManager` |
| SwiftUI view | `struct`, UpperCamelCase noun/noun phrase | `StationListView`, `StationRow`, `HikeAlertBanner` |
| Data Transfer Object | `struct`, UpperCamelCase + `DTO` suffix | `StationDTO`, `FuelPriceDTO` |
| Protocol | UpperCamelCase, describes capability | `FuelPriceService` |
| Enum (model-scoped) | nested inside owning type, UpperCamelCase cases | `Station.RAGStatus`, `UserProfile.Rank` |
| Enum (view-scoped) | nested inside owning view or service, UpperCamelCase | `StationListView.SortOption`, `NavigationApp` |
| Singleton | `static let shared`, private `init()` | `NavigationService.shared`, `OCRService.shared` |
| Async stream | noun + `Events` suffix | `exitEvents`, `regionEvents` |

---

## Architecture Patterns

### Services vs. Managers

- **Service** — stateless or narrowly stateful, wraps a single system capability (location, geofence, search, navigation, OCR). Injected via SwiftUI `@Environment`.
- **Manager** — stateful, owns a SwiftData `ModelContext`, orchestrates business logic across models (gamification, ingestion). Injected via SwiftUI `@Environment`.

Both categories are declared `@Observable final class` and passed into the view hierarchy as environment objects from `ContentView` or `refuelApp`.

### Dependency Injection

- Services and managers are created once at the `ContentView` level (or `refuelApp` level for the `ModelContainer`) and injected downward via `.environment(_:)`.
- Child views declare dependencies with `@Environment(SomeType.self)`, never instantiate services themselves.
- `ModelContainer` is the single source of truth; each manager that needs persistence creates its own `ModelContext` from the shared container rather than sharing one context across threads.

### SwiftData Access

- The main-thread `@Environment(\.modelContext)` is used in views for inserts, deletes, and saves triggered directly by user interaction.
- Background/actor-isolated work (ingestion) uses `@ModelActor` (`FuelPriceIngestor`) and constructs a dedicated `ModelContext` inside the actor.
- `@Query` is the preferred way to read collections in views; manual `FetchDescriptor` fetches are used only inside services and managers where `@Query` is unavailable.
- `try? modelContext.save()` is acceptable for non-critical saves (gamification, price verification). `try modelContext.save()` with proper error propagation is required for the ingestor, which operates on the primary data path.

### Concurrency

- `@Observable` services use `Task { }` blocks to bridge into async contexts from synchronous `init` or delegate callbacks.
- `@ModelActor` actors enforce that all SwiftData mutations happen off the main thread during bulk ingestion.
- `AsyncStream` is used to bridge delegate-based callbacks (CLLocationManager, CLMonitor) into the structured concurrency world. Streams are declared as `let` on the service and fed via a captured `Continuation`.
- `@MainActor` is applied to individual methods in `GamificationManager` that touch the model context from the main thread, rather than marking the entire class `@MainActor`.
- `defer { isRefreshing = false }` is the standard pattern for resetting loading flags after async work, ensuring cleanup even on early returns or throws.

---

## SwiftUI Conventions

### View Composition

- Complex views are broken into sub-views at logical boundaries (e.g., `StationRow` extracted from `StationListView`, `HikeAlertBanner` extracted from `ContentView`, `StatCard` extracted from `ProfileView`).
- Reusable layout primitives (e.g., `FlowLayout`) live in the same file as their first consumer unless used in three or more places, at which point they get their own file.
- `MARK: -` comments delimit logical sections within a file (e.g., `// MARK: - CLLocationManagerDelegate`, `// MARK: - Hike Alerts`, `// MARK: - History Views`).

### State Management

- `@State` is used for local, ephemeral UI state.
- `@State private var someService = SomeService()` is the pattern for creating observable service instances owned by a view (used at `ContentView` level).
- `@Binding` is passed down for two-way communication between parent and child (e.g., `triggerCapture` in `PriceBoardScannerView`).
- Boolean state flags that gate sheet presentation follow the pattern `@State private var showingXxx = false`.

### Sheet and Navigation Presentation

- Sheets are always presented from a single `.sheet(isPresented:)` or `.sheet(item:)` modifier per concern — not nested.
- `NavigationStack` is the root of every tab's navigation tree. Sheets that need navigation also wrap in `NavigationStack`.
- `ToolbarItem(placement: .cancellationAction)` / `.confirmationAction` are used instead of freeform `.topBarLeading` / `.topBarTrailing` placements for standard Cancel/Save/Done actions.
- Detail views pushed via `NavigationLink` use `.navigationBarTitleDisplayMode(.inline)`.

### Loading and Empty States

- A translucent `ProgressView` overlay with `.ultraThinMaterial` background and `.cornerRadius(16)` is the standard full-screen loading indicator.
- `ContentUnavailableView` (iOS 17+) is used for empty list states with a system image and descriptive text.
- Pull-to-refresh is surfaced via `.refreshable { await callback?() }` where the view accepts an `onRefresh: (() async -> Void)?` closure.

### Accessibility

- Interactive map annotations include `.accessibilityLabel`, `.accessibilityValue`, and `.accessibilityAction` modifiers.
- Favorite toggle buttons include `.accessibilityLabel` and `.accessibilityValue` strings reflecting current state.
- Price labels use formatted string accessibilityLabels (e.g., `"Price: $2.85"`).

---

## Data Model Conventions

- All `@Model` classes use `@Attribute(.unique) var id: UUID` as their primary key, defaulting to `UUID()` in `init`.
- Optional attributes (`openingHours`, `services`, `lastUpdated`, `zScore`) use Swift optionals; non-optional attributes have sensible defaults.
- Computed properties derived from persisted state (e.g., `ragStatus`, `isStale`, `totalCost`, `rank`) live on the model class itself.
- Cascade delete rules are declared explicitly on `@Relationship` when child objects are owned (`deleteRule: .cascade`).
- Staleness threshold: price data older than 4 hours is considered stale (`isStale` on `Station`).

### RAG Status

The five-tier RAG system is the canonical value visualisation. Status is derived from the z-score of each station's minimum price relative to the local area mean:

| Z-Score Range | Status | Color |
|---|---|---|
| < -1.5 | `exceptional` | Dark Green |
| -1.5 to < -0.5 | `good` | Green |
| -0.5 to 0.5 | `average` | Amber |
| 0.5 to 1.5 | `expensive` | Orange |
| > 1.5 | `avoid` | Red |

Z-scores are computed using `vDSP` (Accelerate framework) for efficiency. Analytics are always recalculated on the full station set, never per-station in isolation.

---

## Service Layer Conventions

### Protocol + Mock pattern

External data dependencies are defined as protocols (`FuelPriceService`) with a `Mock` concrete implementation (`MockFuelPriceService`). This allows views and tests to run without a live API.

### Singleton services

Services with a single app-wide instance and no dependency on SwiftData (`NavigationService`, `OCRService`) use the `static let shared` singleton pattern with a private initialiser. Services that need a `ModelContext` are not singletons — they are instantiated with the `ModelContainer` and injected.

### Logging

`OSLog` (`Logger(subsystem:category:)`) is used in all services that interact with system APIs (geofencing, notifications). The subsystem is `"com.slade.refuel"` and the category matches the class name. `print()` is acceptable for debug output in views and for non-critical error paths that are not system-API-adjacent.

---

## UIKit Bridging

- UIKit view controllers (document camera, data scanner, `UIActivityViewController`) are wrapped in `UIViewControllerRepresentable` structs.
- Coordinators are nested `class Coordinator: NSObject` within the representable, conforming to the required delegate protocol.
- Callbacks from the coordinator back to the SwiftUI layer use closure properties on the parent representable (`onCompletion`, `onCapture`).
- `@Environment(\.dismiss)` is used inside representables that need to dismiss themselves.

---

## Testing Conventions

- Swift Testing (`import Testing`, `#expect`, `@Test`) is used for all unit tests. XCTest is reserved for UI tests only.
- Test structs are `@MainActor` when they interact with SwiftData or `@Observable` objects.
- In-memory `ModelContainer` instances (`ModelConfiguration(isStoredInMemoryOnly: true)`) are created fresh per test struct via `init()`.
- `@testable import refuel` is always present. Internal methods that need testing are declared `internal` (not `private`), with a comment noting the visibility choice (e.g., `OCRService.parseText`, `OCRService.extractDecimal`).
- Test names use sentence-case descriptions of the behaviour being verified (`testZScoreCalculation`, `testRAGStatusMapping`, `testReceiptParsing`).

---

## Gamification Constants

XP awards are defined inline at the call site (not in a constants file) and must follow this scale until a dedicated constants layer is introduced:

| Action | XP |
|---|---|
| Manual refuel log entry | 10 |
| Price board scan (capture) | 30 |
| Receipt scan (OCR) | 50 |
| Price verification | 10 |

Streak grace period: 10 days (a contribution within 10 calendar days of the last extends the streak rather than resetting it).
