# Coding Conventions

**Analysis Date:** 2026-04-12

## Naming Patterns

**Files:**
- [Pattern]: Match the primary type defined in the file.
- Example: `StationListView.swift` contains `struct StationListView`.

**Functions:**
- [Pattern]: camelCase, starting with a verb.
- Example: `func startLocationUpdates()`, `func requestPermission()`.

**Variables:**
- [Pattern]: camelCase.
- Example: `var userLocation`, `let filterFavorites`.

**Types:**
- [Pattern]: PascalCase.
- Example: `final class LocationManager`, `struct StationRow`.

## Code Style

**Formatting:**
- [Tool used]: Standard Swift formatting (likely Xcode's default).
- [Key settings]: 4-space indentation, consistent spacing around operators and braces.

**Linting:**
- [Tool used]: Not explicitly detected (no .swiftlint.yml found).
- [Key rules]: Follows modern Swift 6 paradigms.

## Import Organization

**Order:**
1. Standard Library / Foundation (`import Foundation`)
2. Apple Frameworks (`import SwiftUI`, `import SwiftData`, `import CoreLocation`)
3. Internal Modules (via `@testable import refuel` in tests)

**Path Aliases:**
- Not used.

## Error Handling

**Patterns:**
- Extensive use of `do-catch` blocks for async operations.
- `try?` for optional results where failure is non-critical.
- `try!` in `#Preview` or setup code where failure indicates a fatal programmer error.
- Error propagation via `throws` in services.

## Logging

**Framework:** `print()` for simple console logging.

**Patterns:**
- `print("Error message: \(error)")` inside catch blocks.

## Comments

**When to Comment:**
- Minimal commenting within method bodies.
- `MARK: - [Section]` used for organizing protocol implementations or logical groups in large files.

**JSDoc/TSDoc:**
- Not explicitly used, but standard Swift triple-slash `///` documentation is expected for public APIs (though limited in current codebase).

## Function Design

**Size:** Small, focused functions.

**Parameters:** Mostly unnamed or with descriptive labels.

**Return Values:** Uses standard return types or `Result` types (implicitly via `throws`).

## Module Design

**Exports:** Public/Internal by default (standard Swift module structure).

**Barrel Files:** Not applicable in Swift.

**Class Finality:** Extensive use of `final class` for managers and models to prevent subclassing and improve performance.
- Examples: `final class Station`, `final class LocationManager`.

---

*Convention analysis: 2026-04-12*
