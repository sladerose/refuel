<!-- GSD:project-start source:PROJECT.md -->
## Project

**Refuel**

Refuel is an iOS app for car owners that helps them find and track the cheapest fuel prices in their area. It uses a hybrid Map/List interface with RAG (Red-Amber-Green) status indicators to visualize price comparisons within an adjustable geofenced area.

**Core Value:** Users can quickly identify and navigate to the fuel station offering the best price within their preferred search radius.

### Constraints

- **Platform**: iOS 18+ (SwiftUI, MapKit, SwiftData)
- **Data Source**: External fuel price API (TBD)
- **Permissions**: Location services required for proximity features
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Swift 6.0 - Used for all application logic, UI, and data models.
## Runtime
- iOS 18.0+ (implied by SwiftData and Swift Testing framework usage)
- Swift Package Manager (built into Xcode)
- Lockfile: `project.xcworkspace/xcshareddata/swiftpm/configuration/` (Note: No external dependencies currently added)
## Frameworks
- SwiftUI - Declarative UI framework.
- SwiftData - Modern data persistence framework.
- Swift Testing - New framework for unit tests.
- XCTest - Used for UI testing.
- Xcode 16+ - Development IDE and build system.
## Key Dependencies
- `SwiftData` - Core data management.
- `SwiftUI` - Core interface.
## Configuration
- Configured via Build Settings in `refuel.xcodeproj`.
- `refuel.xcodeproj/project.pbxproj`
## Platform Requirements
- macOS with Xcode 16+
- iOS 18.0+
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- **Declarative UI:** Built entirely using SwiftUI views.
- **Modern Persistence:** Uses SwiftData (model context and container) for data management.
- **Preview Support:** Uses SwiftData in-memory previews for development.
## Layers
- Purpose: Defines the data schema for the application.
- Location: `refuel/Item.swift`
- Contains: SwiftData models.
- Depends on: `SwiftData`, `Foundation`.
- Used by: View layer.
- Purpose: Presentation and user interaction.
- Location: `refuel/ContentView.swift`
- Contains: SwiftUI views, query logic, and interaction handlers.
- Depends on: `SwiftUI`, `SwiftData`.
- Used by: App entry point.
- Purpose: Sets up the main window and provides the environment (model container).
- Location: `refuel/refuelApp.swift`
- Contains: `@main` app struct and global container configuration.
- Depends on: `SwiftUI`, `SwiftData`.
- Used by: iOS Runtime.
## Data Flow
- SwiftData manages the object graph and persistence.
- SwiftUI `@Environment(\.modelContext)` provides access to the context.
## Key Abstractions
- Purpose: Manages the schema and persistent store.
- Examples: `sharedModelContainer` in `refuel/refuelApp.swift`.
- Pattern: Dependency injection via environment.
## Entry Points
- Location: `refuel/refuelApp.swift`
- Triggers: Application launch.
- Responsibilities: Initializes the `ModelContainer` and sets up the root view.
## Error Handling
- `fatalError()` used in `ModelContainer` creation if the schema or configuration is invalid.
## Cross-Cutting Concerns
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
