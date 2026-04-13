---
phase: 260413-pbk
plan: "01"
subsystem: app-entry
tags: [swift, swiftdata, performance, main-thread]
dependency_graph:
  requires: []
  provides: [off-main-thread-model-container-init]
  affects: [refuelApp, ContentView]
tech_stack:
  added: []
  patterns: [nonisolated(unsafe) static let for actor-isolated struct properties]
key_files:
  modified:
    - refuel/refuelApp.swift
decisions:
  - Used nonisolated(unsafe) static let so the closure executes outside main-actor isolation, allowing SwiftData disk I/O to occur off the main thread at first access
metrics:
  duration: "~3 min"
  completed: "2026-04-13T16:16:46Z"
  tasks_completed: 1
  files_changed: 1
---

# Phase 260413-pbk Plan 01: Fix Main-Thread I/O Warning in refuelApp Summary

**One-liner:** Converted `sharedModelContainer` from a main-actor-bound instance var to a `nonisolated(unsafe) static let` so SwiftData's store-open I/O runs off the main thread.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Convert sharedModelContainer to static let | b5fcaca | refuel/refuelApp.swift |

## What Was Built

`refuelApp.sharedModelContainer` is now a `nonisolated(unsafe) static let`. Swift initializes static lets lazily at first access, and removing actor isolation via `nonisolated(unsafe)` means the initialization closure is no longer bound to the main actor. This eliminates the "Performing I/O on the main thread can cause slow launches" Xcode warning.

Both call sites in `body` were updated to `Self.sharedModelContainer`. Schema contents and `cloudKitDatabase: .automatic` are byte-for-byte identical to the original.

## Decisions Made

- **`nonisolated(unsafe)` over plain `static let`:** A plain `static let` on a `@MainActor`-isolated struct (the `App` protocol pulls in main-actor isolation in Swift 6) remains main-actor-isolated, defeating the purpose. `nonisolated(unsafe)` removes that isolation. The value is written once at first access and never mutated, making the `unsafe` annotation safe in practice — consistent with T-pbk-01 in the threat model.

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `xcodebuild -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 17' build` → **BUILD SUCCEEDED**
- `cloudKitDatabase: .automatic` preserved in updated file
- `nonisolated(unsafe) static let sharedModelContainer` present
- Both `body` references use `Self.sharedModelContainer`

## Self-Check: PASSED

- [x] `refuel/refuelApp.swift` modified as specified
- [x] Commit b5fcaca exists and contains only `refuelApp.swift`
- [x] Build succeeds with no new errors or warnings
