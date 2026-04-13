---
phase: 260413-pbk
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - refuel/refuelApp.swift
autonomous: true
requirements:
  - FIX-MAIN-THREAD-IO
must_haves:
  truths:
    - "Xcode no longer reports the main-thread I/O warning on launch"
    - "CloudKit private database sync continues to work (cloudKitDatabase: .automatic preserved)"
    - "The app compiles and launches without errors"
  artifacts:
    - path: "refuel/refuelApp.swift"
      provides: "ModelContainer initialized off main thread"
      contains: "static let"
  key_links:
    - from: "refuelApp body"
      to: "sharedModelContainer"
      via: "static property access"
      pattern: "refuelApp\\.sharedModelContainer"
---

<objective>
Move ModelContainer initialization off the main thread to eliminate the Xcode "Performing I/O on the main thread can cause slow launches" warning.

Purpose: SwiftData's ModelContainer performs disk I/O when it opens the persistent store. Running that inside a stored-property initializer on the @main App struct executes it synchronously on the main thread during launch, which Xcode flags as a performance issue.

Output: refuelApp.swift updated to use a static let for sharedModelContainer, preserving the existing schema and cloudKitDatabase: .automatic configuration.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Convert sharedModelContainer to a static let</name>
  <files>refuel/refuelApp.swift</files>
  <action>
Replace the instance stored property:

```swift
var sharedModelContainer: ModelContainer = { ... }()
```

with a `nonisolated(unsafe) static let`:

```swift
nonisolated(unsafe) static let sharedModelContainer: ModelContainer = { ... }()
```

The closure body is unchanged — same schema array (Station, FuelPrice, RefuelEvent, UserProfile, LuckyDrawEntry), same ModelConfiguration with isStoredInMemoryOnly: false and cloudKitDatabase: .automatic, same fatalError fallback.

In the body property, update both references from the bare `sharedModelContainer` to `refuelApp.sharedModelContainer` (or `Self.sharedModelContainer`) so they resolve correctly on the static property:

```swift
var body: some Scene {
    WindowGroup {
        ContentView(modelContainer: Self.sharedModelContainer)
    }
    .modelContainer(Self.sharedModelContainer)
}
```

Why `nonisolated(unsafe) static let`: A plain `static let` on a `@MainActor`-isolated struct (`App` conformance pulls in main actor isolation in Swift 6) would itself be main-actor-isolated, defeating the purpose. `nonisolated(unsafe)` removes the actor isolation requirement so Swift can initialize it on a background thread. The value is set once at first access and never mutated, making the `unsafe` annotation safe in practice.
  </action>
  <verify>
    <automated>xcodebuild -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20</automated>
  </verify>
  <done>
    - refuelApp.swift compiles cleanly with no errors or warnings about main-thread I/O
    - The static property is present and both body references use Self.sharedModelContainer
    - No change to schema or CloudKit configuration
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| App launch → SwiftData store | ModelContainer opens/creates the on-disk SQLite store; no untrusted input crosses here |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-pbk-01 | Information Disclosure | nonisolated(unsafe) static | accept | Property is write-once at first access, read-only thereafter; no PII exposed, no mutation path |
| T-pbk-02 | Denial of Service | fatalError on container failure | accept | Existing behavior preserved; fatalError on misconfigured schema is appropriate during development |
</threat_model>

<verification>
After the task completes:
1. Build succeeds: `xcodebuild -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' build` exits 0
2. No "Performing I/O on the main thread" warning in the Xcode Issue Navigator
3. App launches on simulator without crash
4. CloudKit configuration line `cloudKitDatabase: .automatic` is present in the updated file
</verification>

<success_criteria>
- refuelApp.swift uses `nonisolated(unsafe) static let sharedModelContainer`
- Schema and ModelConfiguration are byte-for-byte identical to the original
- Clean build with no new warnings
- Existing CloudKit sync behaviour unaffected
</success_criteria>

<output>
After completion, create `.planning/quick/260413-pbk-fix-main-thread-i-o-warning-in-refuelapp/260413-pbk-SUMMARY.md`
</output>
