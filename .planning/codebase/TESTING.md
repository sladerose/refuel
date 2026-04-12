# Testing Patterns

**Analysis Date:** 2026-04-12

## Test Framework

**Runner:**
- Swift Testing Framework (Apple's modern testing framework introduced in Swift 6/Xcode 16).
- Config: Managed within the Xcode project target `refuelTests`.

**Assertion Library:**
- Standard Swift Testing library via `import Testing`.
- Key assertions: `#expect(condition)`.

**Run Commands:**
```bash
# Executed via Xcode:
Command + U           # Run all tests
Command + Alt + U     # Run selected tests
```

## Test File Organization

**Location:**
- Co-located in a dedicated test target directory: `refuelTests/`.

**Naming:**
- Matches the source file with a `Tests` suffix.
- Example: `OCRServiceTests.swift` for `OCRService.swift`.

**Structure:**
```
refuelTests/
├── GeofenceTests.swift
├── NavigationServiceTests.swift
├── OCRServiceTests.swift
├── refuelTests.swift
└── ValueAnalyticsTests.swift
```

## Test Structure

**Suite Organization:**
```typescript
import Testing
@testable import refuel

@MainActor // Optional: depends on whether testing UI-related or async-main code
struct ComponentTests {
    // Setup logic can be in init()
    init() {
        // ... initial setup ...
    }

    @Test func testFunctionality() async throws {
        // Given
        // ... arrangement ...

        // When
        // ... action ...

        // Then
        #expect(result == expected)
    }
}
```

**Patterns:**
- **Setup pattern:** Using `init()` in test structs to initialize state (e.g., in-memory `ModelContainer`).
- **Teardown pattern:** Not explicitly used, as structs are recreated for each test.
- **Assertion pattern:** Use `#expect` for logic checks and `throws` for expected error cases.

## Mocking

**Framework:** Manual dependency injection and state setup. No external mocking library detected.

**Patterns:**
```typescript
@Test func testReceiptParsing() async throws {
    // Create actual model instances for use in the test
    let stations = [
        Station(name: "Shell", address: "123 Road", latitude: 0, longitude: 0),
        Station(name: "BP", address: "456 Road", latitude: 0, longitude: 0)
    ]
    
    // Call the service under test
    let data = ocrService.parseText(lines, stations: stations)
    
    // Assert against results
    #expect(data.stationName == "Shell")
}
```

**What to Mock:**
- Network responses (via local service injection if needed, though not explicitly shown in tests).
- Local databases (using in-memory `SwiftData` containers).

**What NOT to Mock:**
- Business logic models (`Station`, `FuelPrice`).
- Calculations (tested directly with tolerances).

## Fixtures and Factories

**Test Data:**
```typescript
let s1 = Station(name: "S1", address: "A1", latitude: 0, longitude: 0)
let p1 = FuelPrice(grade: "91", price: 1.0, station: s1)
```

**Location:**
- Inline within test functions or `init()`. No separate shared fixture files detected.

## Coverage

**Requirements:** None enforced in CI at this stage.

**View Coverage:**
- Xcode "Report" navigator after running tests.

## Test Types

**Unit Tests:**
- Focus on logic in `Service` and `Manager` classes.
- Examples: `OCRServiceTests.swift`, `ValueAnalyticsTests.swift`.

**Integration Tests:**
- Testing interaction between `SwiftData` models and logic.
- Example: `ValueAnalyticsTests.swift` (using a real `ModelContainer`).

**E2E Tests:**
- UI tests located in `refuelUITests/`.
- Uses `XCTest` framework (Standard UI testing practice).

## Common Patterns

**Async Testing:**
- Marked with `async throws` to support modern Swift concurrency.
- Example: `await service.monitorRegion(...)`.

**Error Testing:**
- Use `#expect(throws: ...)` or similar where applicable (not heavily shown in current examples).

---

*Testing analysis: 2026-04-12*
