# Technology Stack

**Analysis Date:** 2024-05-24

## Languages

**Primary:**
- Swift 6.0 - Used for all application logic, UI, and data models.

## Runtime

**Environment:**
- iOS 18.0+ (implied by SwiftData and Swift Testing framework usage)

**Package Manager:**
- Swift Package Manager (built into Xcode)
- Lockfile: `project.xcworkspace/xcshareddata/swiftpm/configuration/` (Note: No external dependencies currently added)

## Frameworks

**Core:**
- SwiftUI - Declarative UI framework.
- SwiftData - Modern data persistence framework.

**Testing:**
- Swift Testing - New framework for unit tests.
- XCTest - Used for UI testing.

**Build/Dev:**
- Xcode 16+ - Development IDE and build system.

## Key Dependencies

**Critical:**
- `SwiftData` - Core data management.
- `SwiftUI` - Core interface.

## Configuration

**Environment:**
- Configured via Build Settings in `refuel.xcodeproj`.

**Build:**
- `refuel.xcodeproj/project.pbxproj`

## Platform Requirements

**Development:**
- macOS with Xcode 16+

**Production:**
- iOS 18.0+

---

*Stack analysis: 2024-05-24*
