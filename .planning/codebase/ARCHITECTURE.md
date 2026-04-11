# Architecture

**Analysis Date:** 2024-05-24

## Pattern Overview

**Overall:** SwiftUI with SwiftData for persistence.

**Key Characteristics:**
- **Declarative UI:** Built entirely using SwiftUI views.
- **Modern Persistence:** Uses SwiftData (model context and container) for data management.
- **Preview Support:** Uses SwiftData in-memory previews for development.

## Layers

**Model Layer:**
- Purpose: Defines the data schema for the application.
- Location: `refuel/Item.swift`
- Contains: SwiftData models.
- Depends on: `SwiftData`, `Foundation`.
- Used by: View layer.

**View Layer:**
- Purpose: Presentation and user interaction.
- Location: `refuel/ContentView.swift`
- Contains: SwiftUI views, query logic, and interaction handlers.
- Depends on: `SwiftUI`, `SwiftData`.
- Used by: App entry point.

**App Entry Point:**
- Purpose: Sets up the main window and provides the environment (model container).
- Location: `refuel/refuelApp.swift`
- Contains: `@main` app struct and global container configuration.
- Depends on: `SwiftUI`, `SwiftData`.
- Used by: iOS Runtime.

## Data Flow

**SwiftData Cycle:**

1. **Query:** `ContentView.swift` uses `@Query` to fetch items from the `modelContext`.
2. **Action:** `addItem()` or `deleteItems()` modify the `modelContext`.
3. **Reactive Update:** SwiftUI automatically re-renders the views when the context changes.

**State Management:**
- SwiftData manages the object graph and persistence.
- SwiftUI `@Environment(\.modelContext)` provides access to the context.

## Key Abstractions

**Model Container:**
- Purpose: Manages the schema and persistent store.
- Examples: `sharedModelContainer` in `refuel/refuelApp.swift`.
- Pattern: Dependency injection via environment.

## Entry Points

**App Entry:**
- Location: `refuel/refuelApp.swift`
- Triggers: Application launch.
- Responsibilities: Initializes the `ModelContainer` and sets up the root view.

## Error Handling

**Strategy:** Fail-fast for critical initialization.

**Patterns:**
- `fatalError()` used in `ModelContainer` creation if the schema or configuration is invalid.

## Cross-Cutting Concerns

**Logging:** Standard console output (implicit).
**Validation:** SwiftData model types provide basic type safety.
**Authentication:** Not implemented in this template.

---

*Architecture analysis: 2024-05-24*
