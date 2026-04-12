# Architecture

**Analysis Date:** 2024-05-13

## Pattern Overview

**Overall:** SwiftUI with SwiftData and Model-Actor (MVVM-ish with SwiftData integration)

**Key Characteristics:**
- **SwiftUI Views**: Reactive UI that queries SwiftData directly using `@Query`.
- **SwiftData Models**: Persistent storage and domain logic encapsulation.
- **ModelActors**: Background data processing, ingestion, and heavy calculations using SwiftData's actor-based concurrency.
- **Service Layer**: Protocol-oriented external integration (e.g., `FuelPriceService`).

## Layers

**UI Layer (Views):**
- Purpose: Render user interface and handle user interaction.
- Location: `refuel/*.swift` (suffixed with `View.swift`)
- Contains: SwiftUI Views, local `@State`, `@Query` for data access.
- Depends on: `Models`, `Managers` (via `@Environment`), `Services`.
- Used by: App entry point.

**Persistence & Logic Layer (Models):**
- Purpose: Define data structure, relationships, and basic derived logic (e.g., `ragStatus`, `isStale`).
- Location: `refuel/Models.swift`
- Contains: `@Model` classes for `Station`, `FuelPrice`, `RefuelEvent`, `UserProfile`, `LotteryEntry`.
- Depends on: None.
- Used by: Views, Ingestors, Services.

**Business Logic Layer (Ingestors/Actors):**
- Purpose: Perform background tasks, data sync, and heavy analytics (z-score calculation).
- Location: `refuel/FuelPriceIngestor.swift`, `refuel/ProactiveService.swift`
- Contains: `@ModelActor` classes.
- Depends on: `Models`, `Services`.
- Used by: Views (via explicit calls).

**Infrastructure Layer (Services/Managers):**
- Purpose: Handle external side effects like Location, Notifications, Camera/OCR, and API calls.
- Location: `refuel/*Service.swift`, `refuel/*Manager.swift`
- Contains: `@Observable` classes, Protocols.
- Depends on: System frameworks (CoreLocation, UserNotifications, Vision).
- Used by: Views.

## Data Flow

**Data Ingestion & Refresh:**

1. `ContentView` or `StationListView` triggers a refresh (e.g., `.task` or `.refreshable`).
2. The view calls `FuelPriceIngestor.updatePrices(latitude:longitude:service:)`.
3. `FuelPriceIngestor` (as an Actor) fetches data from `FuelPriceService` (Mock or Real).
4. `FuelPriceIngestor` maps DTOs to `Station` and `FuelPrice` models, updating the `ModelContext`.
5. `FuelPriceIngestor` recalculates analytics (z-scores) for all stations.
6. `ModelContext` saves, and SwiftUI `@Query` automatically updates the UI.

**State Management:**
- **Persistent State**: Managed by SwiftData (`@Model`).
- **Transient/Global State**: Managed by `@Observable` classes (e.g., `LocationManager`, `GamificationManager`) injected into the SwiftUI environment.
- **Local View State**: Managed by `@State` and `@Binding`.

## Key Abstractions

**FuelPriceService (Protocol):**
- Purpose: Abstract fuel price data fetching from external providers.
- Examples: `refuel/FuelPriceService.swift`
- Pattern: Strategy / Protocol-Oriented.

**ModelActor (SwiftData Pattern):**
- Purpose: Perform safe background data operations.
- Examples: `refuel/FuelPriceIngestor.swift`
- Pattern: Actor-based concurrency.

## Entry Points

**App Entry:**
- Location: `refuel/refuelApp.swift`
- Triggers: System launch.
- Responsibilities: Initialize `ModelContainer`, inject shared managers into the environment, set up the root `ContentView`.

## Error Handling

**Strategy:** Result types and `do-catch` blocks in asynchronous tasks.

**Patterns:**
- **Async/Await**: Used throughout for concurrency.
- **Service Errors**: Services throw standard Swift errors.
- **UI Feedback**: Currently basic (e.g., console logs or empty states).

## Cross-Cutting Concerns

**Location Management:** Centralized in `refuel/LocationManager.swift`.
**Gamification:** Managed by `refuel/GamificationManager.swift`, awarding XP for various user actions.
**Background Ingestion:** Handled by `refuel/FuelPriceIngestor.swift`.
**OCR/Vision:** Abstracted in `refuel/OCRService.swift`.

---

*Architecture analysis: 2024-05-13*
