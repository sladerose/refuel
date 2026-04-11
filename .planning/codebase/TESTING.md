# Testing Patterns

**Analysis Date:** 2024-05-24

## Test Framework

**Runner:**
- Swift Testing Framework (Unit Tests)
- XCTest (UI Tests)
- Config: Managed via Xcode project targets and schemes.

**Assertion Library:**
- `Testing` module (`#expect`) for Unit Tests.
- `XCTest` module (`XCTAssert`) for UI Tests.

**Run Commands:**
```bash
# In Xcode
CMD + U              # Run all tests
```

## Test File Organization

**Location:**
- Separate targets: `refuelTests/` and `refuelUITests/`.

**Naming:**
- PascalCase with suffix: `refuelTests.swift`, `refuelUITests.swift`.

**Structure:**
```
refuelTests/
├── refuelTests.swift
refuelUITests/
├── refuelUITests.swift
└── refuelUITestsLaunchTests.swift
```

## Test Structure

**Suite Organization:**
```swift
import Testing
@testable import refuel

struct refuelTests {
    @Test func example() async throws {
        // ...
    }
}
```

**Patterns:**
- **Unit Testing:** Uses the new `@Test` attribute and `#expect` macro for assertions.
- **UI Testing:** Uses `XCTestCase` with `XCUIApplication()` for end-to-end flow validation.

## Mocking

**Framework:** Not implemented.

**What to Mock:**
- In-memory `ModelContainer` used for testing data-related logic.

## Fixtures and Factories

**Test Data:**
- Currently uses manual instantiation in tests.

**Location:**
- Inline in test methods.

## Coverage

**Requirements:** None enforced.

**View Coverage:**
- Accessible via Xcode Report navigator after running tests.

## Test Types

**Unit Tests:**
- Logic tests for models and view-models (if added).
- Location: `refuelTests/`.

**Integration Tests:**
- Testing model persistence with in-memory containers.

**E2E Tests:**
- UI tests that launch the app and interact with it.
- Location: `refuelUITests/`.

## Common Patterns

**Async Testing:**
- Supports `async throws` test methods in the Swift Testing framework.

**Error Testing:**
- Use `#expect(throws: ...)` in Swift Testing.

---

*Testing analysis: 2024-05-24*
