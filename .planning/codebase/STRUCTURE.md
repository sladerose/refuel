# Codebase Structure

**Analysis Date:** 2024-05-24

## Directory Layout

```
refuel/
├── refuel/                 # Primary app source code
│   ├── Assets.xcassets/    # Images, colors, and app icon
│   ├── ContentView.swift   # Main view implementation
│   ├── Item.swift          # SwiftData model
│   └── refuelApp.swift     # App entry point and environment setup
├── refuelTests/            # Unit testing targets
│   └── refuelTests.swift   # Unit tests using Swift Testing framework
├── refuelUITests/          # UI testing targets
│   ├── refuelUITests.swift # UI test cases
│   └── refuelUITestsLaunchTests.swift # Launch performance tests
└── refuel.xcodeproj        # Xcode project configuration
```

## Directory Purposes

**refuel/:**
- Purpose: Root directory for the main application target.
- Contains: Swift source files and asset catalogs.
- Key files: `refuelApp.swift`, `ContentView.swift`.

**refuelTests/:**
- Purpose: Contains unit tests for models and logic.
- Contains: Swift files using the `Testing` module.
- Key files: `refuelTests.swift`.

**refuelUITests/:**
- Purpose: Contains automated UI tests.
- Contains: Swift files using the `XCTest` module for UI interaction.
- Key files: `refuelUITests.swift`.

## Key File Locations

**Entry Points:**
- `refuel/refuelApp.swift`: Root entry point for the iOS application.

**Configuration:**
- `refuel.xcodeproj`: Project-level settings and build configuration.

**Core Logic:**
- `refuel/Item.swift`: Persistent data model definition.
- `refuel/ContentView.swift`: Primary user interface logic and state management.

**Testing:**
- `refuelTests/refuelTests.swift`: Location for logic/unit tests.
- `refuelUITests/refuelUITests.swift`: Location for interface/E2E tests.

## Naming Conventions

**Files:**
- PascalCase: Matches struct/class names (e.g., `ContentView.swift`).

**Directories:**
- PascalCase (usually matching targets): `refuelTests`.

## Where to Add New Code

**New Feature:**
- Primary code: `refuel/`
- Tests: `refuelTests/`

**New Component/Module:**
- Implementation: `refuel/Views/` (suggested directory) or root `refuel/`.

**Utilities:**
- Shared helpers: `refuel/Utilities/` (suggested directory).

## Special Directories

**Assets.xcassets:**
- Purpose: Manages static resources.
- Generated: No (manually managed).
- Committed: Yes.

---

*Structure analysis: 2024-05-24*
