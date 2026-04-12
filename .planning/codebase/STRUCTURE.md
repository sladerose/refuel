# Codebase Structure

**Analysis Date:** 2024-05-13

## Directory Layout

```
refuel/
├── refuel/               # Primary source code
│   ├── Assets.xcassets/  # Images, colors, and app icons
│   ├── *.swift           # All source files (Views, Models, Services)
├── refuelTests/          # Unit tests
├── refuelUITests/        # UI tests
└── refuel.xcodeproj/     # Xcode project configuration
```

## Directory Purposes

**refuel/refuel/:**
- Purpose: Contains all application source code, resources, and assets.
- Contains: SwiftUI views, SwiftData models, Service implementations, and Assets.
- Key files: `refuelApp.swift`, `Models.swift`, `ContentView.swift`.

**refuelTests/:**
- Purpose: Unit testing for services and models.
- Contains: XCTest files.
- Key files: `GeofenceTests.swift`, `OCRServiceTests.swift`.

**refuelUITests/:**
- Purpose: End-to-end UI testing.
- Contains: XCUITest files.

## Key File Locations

**Entry Points:**
- `refuel/refuel/refuelApp.swift`: App lifecycle and environment setup.
- `refuel/refuel/ContentView.swift`: Main UI navigation hub.

**Configuration:**
- `refuel/refuel/Assets.xcassets/`: App colors (AccentColor) and icons.
- `refuel/refuel/refuelApp.swift`: SwiftData schema and container configuration.

**Core Logic:**
- `refuel/refuel/Models.swift`: Data models and derived properties.
- `refuel/refuel/FuelPriceIngestor.swift`: Background data processing and analytics.
- `refuel/refuel/GamificationManager.swift`: User progression and rewards logic.

**Testing:**
- `refuelTests/`: Unit tests for business logic.

## Naming Conventions

**Files:**
- Views: `[Name]View.swift` (e.g., `StationListView.swift`)
- Services: `[Name]Service.swift` (e.g., `FuelPriceService.swift`)
- Managers: `[Name]Manager.swift` (e.g., `LocationManager.swift`)
- Ingestors: `[Name]Ingestor.swift` (e.g., `FuelPriceIngestor.swift`)

**Directories:**
- Flat structure currently used for source files.

## Where to Add New Code

**New Feature:**
- UI components: `refuel/refuel/[Feature]View.swift`
- Logic/Coordination: `refuel/refuel/[Feature]Manager.swift` or `[Feature]Service.swift`
- Tests: `refuelTests/[Feature]Tests.swift`

**New Model:**
- Add to `refuel/refuel/Models.swift` and register in `refuelApp.swift`'s `Schema`.

**Utilities:**
- Currently added as extensions or top-level functions within relevant files.

## Special Directories

**Assets.xcassets/:**
- Purpose: Asset catalog for images and colors.
- Generated: No (Managed by developer)
- Committed: Yes

---

*Structure analysis: 2024-05-13*
