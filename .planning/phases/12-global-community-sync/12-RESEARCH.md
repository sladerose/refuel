# Phase 12: Global Community Sync - Research

**Researched:** 2026-04-13
**Domain:** CloudKit public database, CKRecord CRUD, leaderboard UI (SwiftUI / iOS 18)
**Confidence:** HIGH (core CloudKit API) / MEDIUM (public-DB-specific edge cases)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Auto-generated alias format `Scout#XXXX` where XXXX is the first 4 hex chars of the user's UUID. No onboarding step.
- **D-02:** "You" marker on the leaderboard row — user always sees their own position regardless of rank (sticky footer when scrolled off-screen).
- **D-03:** Global leaderboard — all users worldwide, no geographic filter. "In the area" from the roadmap is overridden.
- **D-04:** Aggregate stats only — one CKRecord per user: alias, xp, rank, communityImpact, total contribution count (scans + verifies). No individual LuckyDrawEntry records synced publicly.
- **D-05:** Sync is triggered on significant events (XP gain, new contribution) — not on every app launch.
- **D-06 (Claude's Discretion):** XP is the ranking metric.
- **D-07:** Opt-in only. Default off. No data written until user enables community sharing.
- **D-08:** If user opts out, their public CKRecord is deleted.

### Claude's Discretion

- Leaderboard UI placement (recommend: tab/navigation entry in existing Rewards Hub / ProfileView area)
- CKRecord schema design and field names
- Exact sync trigger logic and debounce strategy
- Empty leaderboard state handling
- Error handling for CloudKit public DB failures

### Deferred Ideas (OUT OF SCOPE)

- Per-area leaderboard (city/suburb scoped)
- Social following / seeing friends' rankings
- Public LuckyDrawEntry history (individual contributions visible)
</user_constraints>

---

## Summary

Phase 12 introduces a CloudKit **public database** integration — a fundamentally different beast from the SwiftData `.automatic` private-DB sync already working in Phase 11. The public DB is accessed directly via `CKContainer.default().publicCloudDatabase`, bypasses SwiftData entirely, and requires explicit `CKRecord` management with hand-written CRUD operations.

The leaderboard reads are available to all users regardless of iCloud account status. Writes require an authenticated iCloud account (`CKAccountStatus.available`). The public DB has no custom zones, no tombstone mechanism for deletions, and no push-subscription support — making polling (on demand, pull-to-refresh) the correct fetch strategy.

The key architectural decision is that `SocialSyncManager` is an `@Observable` service class (`refuel/*Manager.swift` convention) that holds a `Task` for debounced writes and uses the CloudKit framework directly (not SwiftData). The leaderboard view fetches via `publicCloudDatabase.records(matching:)` with a `CKQuery` sorted by XP descending.

**Primary recommendation:** Use `CKContainer.default().publicCloudDatabase` with direct async/await CKRecord CRUD. One CKRecord per user, with a deterministic `CKRecord.ID` derived from the user's local `UserProfile.id` UUID so upserts work reliably. Guard all writes behind `CKContainer.default().accountStatus() == .available`.

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on This Phase |
|-----------|---------------------|
| Swift 6.0, iOS 18+ only | CloudKit async/await APIs are fully available; Swift 6 concurrency strictness applies to all new code |
| SwiftUI declarative UI | `LeaderboardView`, `LeaderboardRowView`, `CommunitySyncSettingsRow` must be pure SwiftUI structs |
| SwiftData for persistence | `SocialSyncManager` must NOT use SwiftData for CloudKit public DB ops; but reads `UserProfile` from SwiftData to populate sync payload |
| `@ModelActor` for background data ops | Background CloudKit writes follow this pattern (or `Task` inside `@Observable`) |
| `@Observable` for service classes | `SocialSyncManager` must be `@Observable final class` |
| System text styles only | All leaderboard text uses `.headline`, `.caption`, `.body` etc — no fixed point sizes |
| Liquid Glass materials | Leaderboard row cards use `.ultraThinMaterial` |
| `final class` for managers | `SocialSyncManager` must be `final class` |
| 4-space indentation, Swift formatting | Standard Xcode formatting |
| `print()` for error logging | No OSLog or unified logging needed |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| CloudKit | System (iOS 18) | Public database CRUD, `CKRecord`, `CKQuery` | Apple framework, same container as private DB |
| SwiftUI | System (iOS 18) | Leaderboard view, opt-in toggle | Project-wide UI framework |
| Observation | System (iOS 17+) | `@Observable` for `SocialSyncManager` | Established project pattern |

[VERIFIED: codebase grep — CloudKit framework already available via `iCloud.com.refuel.app` container established in Phase 11]

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | System | `UUID`, `Date`, string formatting | Always |
| Swift Concurrency | Swift 6.0 | `async/await`, `Task`, actor isolation | All async CloudKit operations |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct `CKRecord` CRUD | `NSPersistentCloudKitContainer` with public DB | NSPersistentCloudKitContainer public DB support requires Core Data — project uses SwiftData exclusively. Not viable. |
| Direct `CKRecord` CRUD | `CKSyncEngine` | CKSyncEngine only supports private and shared databases, not public. Not viable. [CITED: superwall.com/blog/syncing-data-with-cloudkit] |
| Poll on demand (pull-to-refresh) | CKDatabaseSubscription | Public databases don't support `CKDatabaseSubscription` or zone change operations. Push-based updates are not available. [CITED: fatbobman.com/en/posts/coredatawithcloudkit-5] |

**Installation:** No additional packages. CloudKit is a system framework included via the existing iCloud capability.

---

## Architecture Patterns

### Recommended Project Structure

No new directories needed. New files follow established `refuel/*.swift` convention:

```
refuel/
├── SocialSyncManager.swift    # @Observable service — CloudKit public DB writes, opt-in state
├── LeaderboardView.swift      # LeaderboardView + LeaderboardRowView (same file per UI-SPEC)
├── ProfileView.swift          # Modified — add CommunitySyncSettingsRow + leaderboard nav entry
└── Models.swift               # Modified — add communityAlias computed property to UserProfile
```

### Pattern 1: SocialSyncManager — @Observable Service Class

**What:** `@Observable final class SocialSyncManager` holds the opt-in preference, manages the public DB CKRecord lifecycle (upsert on opt-in / after XP events, delete on opt-out), and exposes leaderboard fetch.

**When to use:** Follows the established `GamificationManager` / `LocationManager` pattern for external side-effect services.

**Key fields exposed:**
- `var isCommunityShareEnabled: Bool` — persisted via `UserDefaults` (not SwiftData, no CloudKit overhead for a bool flag)
- `var leaderboard: [LeaderboardEntry]` — fetched on demand, held transiently
- `var syncState: SyncState` — `.idle | .syncing | .error(String)` for UI feedback

**Example skeleton:**

```swift
// Source: established project pattern (@Observable + async/await — ARCHITECTURE.md)
import Foundation
import CloudKit
import Observation

@Observable
final class SocialSyncManager {
    private let publicDB = CKContainer(identifier: "iCloud.com.refuel.app").publicCloudDatabase
    private let recordType = "ScoutLeaderboard"

    var isCommunityShareEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "communityShareEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "communityShareEnabled") }
    }
    var leaderboard: [LeaderboardEntry] = []
    var syncState: SyncState = .idle

    enum SyncState {
        case idle, syncing, error(String)
    }

    // MARK: - Write

    func upsertPublicRecord(for profile: UserProfile) async {
        guard await accountIsAvailable() else { return }
        let recordID = CKRecord.ID(recordName: profile.id.uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["alias"] = profile.communityAlias as CKRecordValue
        record["xp"] = profile.xp as CKRecordValue
        record["rank"] = profile.rank.rawValue as CKRecordValue
        record["communityImpact"] = profile.communityImpact as CKRecordValue
        record["contributionCount"] = profile.totalContributions as CKRecordValue
        record["lastSynced"] = Date() as CKRecordValue
        do {
            try await publicDB.save(record)
        } catch {
            print("SocialSyncManager: upsert failed: \(error)")
            syncState = .error("Couldn't connect. Your stats are safe — will retry.")
        }
    }

    // MARK: - Delete (opt-out D-08)

    func deletePublicRecord(for profile: UserProfile) async {
        let recordID = CKRecord.ID(recordName: profile.id.uuidString)
        do {
            try await publicDB.deleteRecord(withID: recordID)
        } catch {
            print("SocialSyncManager: delete failed: \(error)")
        }
    }

    // MARK: - Fetch leaderboard

    func fetchLeaderboard(limit: Int = 100) async {
        syncState = .syncing
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "xp", ascending: false)]
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: limit)
            leaderboard = results.compactMap { (_, result) in
                guard let record = try? result.get() else { return nil }
                return LeaderboardEntry(from: record)
            }
            syncState = .idle
        } catch {
            print("SocialSyncManager: fetch failed: \(error)")
            syncState = .error("Couldn't load leaderboard.")
        }
    }

    // MARK: - Account check

    private func accountIsAvailable() async -> Bool {
        let status = try? await CKContainer(identifier: "iCloud.com.refuel.app").accountStatus()
        return status == .available
    }
}
```

[ASSUMED] The `CKDatabase.deleteRecord(withID:)` async method signature — verified conceptually via web search but exact Swift 6 async overload name not confirmed against live Apple docs (JavaScript-gated docs unavailable).

### Pattern 2: Deterministic CKRecord.ID from UserProfile.id

**What:** Use `UserProfile.id.uuidString` as the `CKRecord.ID(recordName:)` value. This makes every write an upsert: saving a record with an existing ID updates it rather than creating a duplicate.

**Why critical:** Without a deterministic ID, every XP event would create a new record, flooding the leaderboard with one user's entries. [CITED: working-with-cloudkit-records section on CKRecord save behavior]

**Example:**
```swift
// Source: CloudKit save() is both create and update when using the same recordID
let recordID = CKRecord.ID(recordName: profile.id.uuidString)
let record = CKRecord(recordType: "ScoutLeaderboard", recordID: recordID)
// Saving this record creates it on first call, updates it on subsequent calls
```

### Pattern 3: CKQuery with sortDescriptors for Leaderboard

**What:** Fetch the top N users sorted by XP descending using `CKQuery` + `NSSortDescriptor`.

**Critical prerequisite:** The `xp` field in the CloudKit schema MUST have a **Sortable index** configured in CloudKit Console before sorted queries will work. Queries on unindexed fields fail with `CKError.invalidArguments`. [CITED: multiple search results confirming CloudKit Dashboard index requirement]

```swift
// Source: swiftwithmajid.com CloudKit pattern + search result confirmation
let query = CKQuery(recordType: "ScoutLeaderboard", predicate: NSPredicate(value: true))
query.sortDescriptors = [NSSortDescriptor(key: "xp", ascending: false)]
let (results, cursor) = try await publicDB.records(matching: query, resultsLimit: 100)
```

### Pattern 4: Sync Trigger via GamificationManager Hook

**What:** After `awardXP(amount:stationName:type:)` completes, call `socialSyncManager.triggerDebouncedSync(profile:)` if community sharing is enabled. Use a `Task` handle with cancellation as the debounce mechanism.

**Why:** D-05 requires event-triggered sync, not every-launch sync. Multiple rapid XP events (streak day + scan) should coalesce to a single write.

```swift
// Source: established project pattern — debounce via Task cancellation
private var pendingSyncTask: Task<Void, Never>?

func triggerDebouncedSync(profile: UserProfile) {
    pendingSyncTask?.cancel()
    pendingSyncTask = Task {
        try? await Task.sleep(for: .seconds(3))
        guard !Task.isCancelled else { return }
        await upsertPublicRecord(for: profile)
    }
}
```

### Pattern 5: UserProfile Extension — communityAlias + totalContributions

**What:** Add computed properties to `UserProfile` to derive the alias and contribution count without storing new SwiftData fields (keeping schema migration-free for this phase).

```swift
// Source: Models.swift inspection + D-01 decision
extension UserProfile {
    var communityAlias: String {
        let hex = id.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let suffix = String(hex.prefix(4)).uppercased()
        return "Scout#\(suffix)"
    }
    // totalContributions requires a LuckyDrawEntry count fetch via modelContext
    // Pass it as a parameter to upsertPublicRecord rather than storing on UserProfile
}
```

### Pattern 6: LeaderboardEntry Value Type

**What:** A lightweight `struct LeaderboardEntry` (not a SwiftData model) to hold fetched public CKRecord data for UI consumption.

```swift
struct LeaderboardEntry: Identifiable {
    let id: String        // CKRecord.ID.recordName (= UserProfile.id.uuidString)
    let alias: String     // "Scout#XXXX"
    let xp: Int
    let rank: String      // rank.rawValue
    let communityImpact: Double
    let contributionCount: Int

    init(from record: CKRecord) {
        id = record.recordID.recordName
        alias = record["alias"] as? String ?? "Scout#????"
        xp = record["xp"] as? Int ?? 0
        rank = record["rank"] as? String ?? "Newcomer"
        communityImpact = record["communityImpact"] as? Double ?? 0
        contributionCount = record["contributionCount"] as? Int ?? 0
    }
}
```

### Pattern 7: Environment Injection of SocialSyncManager

**What:** `SocialSyncManager` is initialized in `ContentViewModel` (alongside `GamificationManager`) and injected into the SwiftUI environment in `ContentView`, matching the established pattern.

```swift
// ContentViewModel.swift — add alongside gamificationManager
var socialSyncManager: SocialSyncManager

// ContentView.swift — add to .environment chain
.environment(viewModel.socialSyncManager)
```

### Anti-Patterns to Avoid

- **Storing `isCommunityShareEnabled` in SwiftData:** This is a device-local preference. `UserDefaults` is appropriate. SwiftData would sync it via CloudKit private DB, creating unnecessary complexity.
- **Creating a new `@Model` for the public record:** The public CKRecord is not a SwiftData model. Do not add it to the `ModelContainer` schema. SwiftData cannot manage public CK records.
- **Using CKSyncEngine for the public DB:** CKSyncEngine only supports private and shared databases. [CITED: superwall.com/blog/syncing-data-with-cloudkit]
- **Querying public DB on every app launch:** Violates D-05. Fetch on: (1) LeaderboardView `.task` / pull-to-refresh, (2) after opt-in write succeeds.
- **Sorting without a CloudKit index:** Will fail at runtime with `CKError`. The `xp` field needs a Sortable index in CloudKit Console before first production query.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Async CKRecord save/fetch | Custom retry/callback wrapper | Native `try await publicDB.save(record)` | CloudKit async/await API built in since iOS 15; complete and battle-tested |
| Leaderboard sort | Client-side sort after full fetch | `CKQuery` with `sortDescriptors` + `resultsLimit` | Server-side sort is vastly more efficient; don't fetch all records to sort locally |
| Duplicate record prevention | Timestamp-based dedup logic | Deterministic `CKRecord.ID` from UUID | CloudKit save() with existing recordID is an atomic upsert — no duplicates possible |
| Debounce | Combine `debounce` operator | `Task` cancellation pattern | No Combine in this project; Task cancel is idiomatic Swift 6 concurrency |

**Key insight:** CloudKit's public database is purpose-built for exactly this use case (community leaderboards). The primitive save/fetch/delete operations are sufficient — no abstraction layer is needed.

---

## CloudKit Schema Design (Claude's Discretion)

### Record Type: `ScoutLeaderboard`

| Field | CK Type | Required Index | Source |
|-------|---------|----------------|--------|
| `alias` | String | Queryable | D-01 |
| `xp` | Int(64) | Queryable + Sortable | D-06 (ranking metric) |
| `rank` | String | Queryable | D-04 |
| `communityImpact` | Double | — | D-04 |
| `contributionCount` | Int(64) | — | D-04 |
| `lastSynced` | Date/Time | — | housekeeping |

**Index requirements:**
- `xp`: Sortable index — required for `NSSortDescriptor(key: "xp")` queries
- `alias`: Queryable index — allows future per-alias lookups (finding own record by alias)
- All queried fields must have at least a Queryable index; unindexed queries return `CKError.invalidArguments`

**Schema creation path:** First write from a development device auto-creates the record type in CloudKit development schema. Fields are inferred from CKRecordValue types. Indexes must be explicitly added via [CloudKit Console](https://icloud.developer.apple.com/dashboard) → Schema → Indexes. Development schema must be promoted to production before App Store release.

[CITED: apple developer archive — Designing and Creating a CloudKit Database; multiple search results confirming index requirement]

---

## Common Pitfalls

### Pitfall 1: Missing CloudKit Indexes Causing Runtime Crash
**What goes wrong:** `records(matching:)` with `sortDescriptors` throws `CKError Code 12` (`invalidArguments`) at runtime if the sorted/queried field has no index.
**Why it happens:** CloudKit indexes are NOT auto-created from code — they must be manually added in CloudKit Console.
**How to avoid:** After the first write (which creates the schema), immediately go to CloudKit Console → Schema → Indexes and add Sortable + Queryable indexes to the `xp` field and Queryable to `alias`. Do this in development before writing any leaderboard fetch code.
**Warning signs:** `CKError.serverRejectedRequest` or `CKError.invalidArguments` on first leaderboard fetch.

### Pitfall 2: Write Without iCloud Account Silently Fails
**What goes wrong:** `publicDB.save(record)` throws `CKError.notAuthenticated` if the user has no iCloud account, but the app may not surface this gracefully.
**Why it happens:** Public DB reads work for everyone; writes require `CKAccountStatus.available`.
**How to avoid:** Always guard writes with `await CKContainer(identifier: "iCloud.com.refuel.app").accountStatus() == .available`. The opt-in toggle should show an appropriate error if the user enables sharing without an iCloud account.
**Warning signs:** `CKError.notAuthenticated` in logs after toggle-on.

### Pitfall 3: Multiple Records Per User (No Upsert)
**What goes wrong:** Each XP event creates a new CKRecord, so the leaderboard shows hundreds of entries for one user.
**Why it happens:** `CKRecord(recordType:)` generates a new UUID-based recordID every time; `save()` creates rather than updates.
**How to avoid:** Always use `CKRecord.ID(recordName: profile.id.uuidString)` when constructing the record. The deterministic ID ensures every save is an upsert. [CITED: rambo.codes CloudKit-101 — "save is used both to create and update records"]
**Warning signs:** Leaderboard shows `Scout#XXXX` appearing multiple times.

### Pitfall 4: Deletion Not Reflected Across Devices (No Tombstones)
**What goes wrong:** After opt-out deletes the CKRecord, other devices that cached the leaderboard still show the deleted user until they re-fetch.
**Why it happens:** Public database has no tombstone mechanism — no deletion events are propagated. [CITED: fatbobman.com/en/posts/coredatawithcloudkit-5]
**How to avoid:** This is acceptable for a leaderboard — stale entries disappear on the next pull-to-refresh. For the leaderboard use case (read-only display, no local caching beyond `var leaderboard: [LeaderboardEntry]`), this is not a data integrity problem. Do NOT implement the soft-delete `isDeleted` workaround — the leaderboard is stateless and re-fetches on demand.
**Warning signs:** N/A — expected behavior. Document it.

### Pitfall 5: Development Schema Not Promoted to Production
**What goes wrong:** The app works in development/TestFlight but crashes on public App Store because the record type and indexes only exist in the development CloudKit environment.
**Why it happens:** CloudKit has separate development and production schemas. Development is the default when running from Xcode.
**How to avoid:** Before App Store release, promote the development schema to production via CloudKit Console → Deploy Schema Changes. This is a Wave 0 / pre-ship gate item.
**Warning signs:** `CKError.unknownItem` in production logs; works in TestFlight but fails for App Store users.

### Pitfall 6: CloudKit Container ID Mismatch
**What goes wrong:** `CKContainer(identifier: "iCloud.com.refuel.app")` works; `CKContainer.default()` may resolve to a different bundle-derived ID if the container ID was ever changed.
**Why it happens:** `CKContainer.default()` uses the bundle ID, which may differ.
**How to avoid:** Always use the explicit `CKContainer(identifier: "iCloud.com.refuel.app")` — the container ID confirmed in `CLOUDKIT_SETUP.md`. [VERIFIED: CLOUDKIT_SETUP.md — container ID is `iCloud.com.refuel.app`]
**Warning signs:** `CKError.permissionFailure` or wrong container being accessed.

### Pitfall 7: Swift 6 Sendability Violations with CKRecord
**What goes wrong:** `CKRecord` is not `Sendable` in Swift 6. Passing it across actor boundaries without `@Sendable` annotation causes compile errors.
**Why it happens:** Swift 6 strict concurrency enforces Sendable boundaries.
**How to avoid:** Extract values from `CKRecord` on the actor that fetched it, then pass the `LeaderboardEntry` struct (which should be `Sendable`) to the main actor. Never pass `CKRecord` directly across async/await boundaries. [ASSUMED — CKRecord Sendability in Swift 6 strict mode: based on Swift 6 concurrency model knowledge, not verified against live Apple headers]

---

## Code Examples

### Complete Leaderboard Fetch Pattern
```swift
// Source: CloudKit async/await API pattern (swiftwithmajid.com + search result confirmation)
func fetchLeaderboard(limit: Int = 100) async {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: "ScoutLeaderboard", predicate: predicate)
    query.sortDescriptors = [NSSortDescriptor(key: "xp", ascending: false)]
    do {
        let (matchResults, _) = try await publicDB.records(matching: query, resultsLimit: limit)
        leaderboard = matchResults.compactMap { (_, result) in
            guard let record = try? result.get() else { return nil }
            return LeaderboardEntry(from: record)
        }
    } catch {
        print("Leaderboard fetch error: \(error)")
    }
}
```

### Account Status Guard
```swift
// Source: cocoacasts.com handling account status + Apple docs CKAccountStatus
private func accountIsAvailable() async -> Bool {
    guard let status = try? await CKContainer(identifier: "iCloud.com.refuel.app").accountStatus() else {
        return false
    }
    return status == .available
}
```

### Opt-In Toggle Handling (SwiftUI)
```swift
// Source: UI-SPEC interaction contract + established ProfileView pattern
Toggle("Community Sharing", isOn: $isSharingOn)
    .tint(.orange)
    .onChange(of: isSharingOn) { _, newValue in
        Task {
            if newValue {
                await socialSyncManager.enableSharing(profile: profile, contributionCount: contributions)
            } else {
                await socialSyncManager.disableSharing(profile: profile)
            }
        }
    }
```

### "You" Sticky Footer Logic
```swift
// Source: UI-SPEC interaction contract — scroll position monitoring
// Use ScrollViewReader + onPreferenceChange to detect when own row leaves viewport
// Show footer overlay when userEntryVisible == false
```

---

## Runtime State Inventory

This is not a rename/refactor/migration phase. No existing runtime state references strings being renamed.

**New runtime state introduced by this phase:**

| Category | Item | Action Required |
|----------|------|----------------|
| Stored data | `UserDefaults` key `"communityShareEnabled"` (Bool) | New key — no migration needed |
| Live service config | CloudKit Console: `ScoutLeaderboard` record type + indexes | Manual setup in CloudKit Console after first dev write |
| OS-registered state | None | — |
| Secrets/env vars | None — uses existing `iCloud.com.refuel.app` container entitlement | None |
| Build artifacts | None | — |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CKOperation completion blocks | `async/await` on `CKDatabase` methods | iOS 15 / WWDC21 | Eliminates nested callbacks; use `try await publicDB.save(record)` directly |
| CKSyncEngine for all sync | CKSyncEngine for private/shared; direct CKRecord API for public | iOS 17 | CKSyncEngine cannot be used for public DB — direct API remains correct approach |
| Polling all fields | `desiredKeys` on CKQueryOperation | Long-standing | Reduce bandwidth: specify only needed keys. For leaderboard: `["alias", "xp", "rank", "communityImpact", "contributionCount"]` |

**Deprecated/outdated:**
- `CKOperation` completion-handler-based API: Still works but the async/await overloads on `CKDatabase` are idiomatic for Swift 6. Use `try await publicDB.save(_:)` not `CKModifyRecordsOperation` for single-record operations.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`) |
| Config file | None — Xcode target `refuelTests` |
| Quick run command | `xcodebuild test -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:refuelTests` |
| Full suite command | `xcodebuild test -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| — | `communityAlias` derived correctly from UUID prefix | unit | `xcodebuild test ... -only-testing:refuelTests/SocialSyncManagerTests` | ❌ Wave 0 |
| — | `LeaderboardEntry(from:)` maps CKRecord fields correctly | unit | same | ❌ Wave 0 |
| — | Debounced sync coalesces rapid calls to single write | unit (mock) | same | ❌ Wave 0 |
| — | Opt-out clears `isCommunityShareEnabled` and triggers delete path | unit (mock) | same | ❌ Wave 0 |
| — | Leaderboard sorted descending by XP | unit (mock data) | same | ❌ Wave 0 |
| — | Empty leaderboard state renders empty state UI | manual | — | manual only |
| — | CloudKit public DB actual write/read | manual (requires device + iCloud account) | — | manual only |

**Note:** CloudKit public database operations cannot be unit-tested without mocking. The `SocialSyncManager` should accept a protocol-typed `database` dependency to enable injection of a mock. See Wave 0 gaps below.

### Sampling Rate

- **Per task commit:** Run `refuelTests` unit target (< 30s on simulator)
- **Per wave merge:** Full scheme test including UI tests
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `refuelTests/SocialSyncManagerTests.swift` — unit tests for alias derivation, LeaderboardEntry mapping, debounce, opt-out logic
- [ ] Protocol `PublicCloudDatabase` (or typealias) to enable mocking `CKDatabase` in tests — or a testable struct wrapping the CK calls
- [ ] `refuelTests/LeaderboardEntryTests.swift` — CKRecord → LeaderboardEntry mapping coverage

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Indirectly | iCloud account status checked before write; opt-in is user-explicit |
| V3 Session Management | No | Handled by CloudKit / iCloud at OS level |
| V4 Access Control | Yes | Public DB security roles: Authenticated write, World read. Creator role means only the record owner can update/delete their own record — enforced by CloudKit automatically. |
| V5 Input Validation | Yes | `alias` derived from UUID (no user input). All numeric fields are typed (`Int`, `Double`) — no string injection risk. |
| V6 Cryptography | No | No custom crypto. CloudKit transport encryption is handled by Apple. |

### Known Threat Patterns for CloudKit Public DB

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Spoofing another user's record | Spoofing | CloudKit Creator role — only the creating iCloud account can update/delete its own record. UUID-derived recordID is not secret but cannot be overwritten by another user. |
| XP inflation (writing arbitrary XP to public record) | Tampering | CloudKit Creator role prevents other users writing to your record. XP source of truth remains in private SwiftData DB. A malicious user can inflate their own displayed XP but cannot affect others. Acceptable risk for a leaderboard. |
| Privacy: alias linkability | Information Disclosure | `Scout#XXXX` alias is derived from UUID prefix — not the user's name, Apple ID, or location. Cannot be reverse-mapped to identity. Opt-in is explicit (D-07). |
| Denial of Service: flooding leaderboard | DoS | Not a significant risk for a fuel app leaderboard. CloudKit rate-limits per-container. |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| iCloud capability (`iCloud.com.refuel.app`) | All CloudKit ops | ✓ (Phase 11 verified) | active | — |
| CloudKit Console access (developer) | Schema index setup | ✓ (same Apple Developer account) | — | — |
| iOS device / Simulator with iCloud account | Testing writes | Requires physical device or configured Simulator | iOS 18 | Manual test on device |
| Xcode 16+ | Build | ✓ (project requirement) | 16+ | — |

[VERIFIED: CLOUDKIT_SETUP.md + STATE.md — `iCloud.com.refuel.app` container configured and verified in Phase 11]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `CKDatabase.deleteRecord(withID:)` is available as an async method (not just completion-handler variant) | Architecture Patterns — Pattern 1 | Would need to wrap completion-handler variant in `withCheckedThrowingContinuation`; extra boilerplate but not blocking |
| A2 | `CKRecord` is not `Sendable` in Swift 6 strict concurrency mode | Common Pitfalls — Pitfall 7 | If it IS Sendable, the precaution is unnecessary but harmless |
| A3 | `public DB.records(matching:resultsLimit:)` returns `([(CKRecord.ID, Result<CKRecord, Error>)], CKQueryOperation.Cursor?)` | Code Examples | Signature may vary slightly in iOS 18 SDK; consult Xcode autocomplete on first use |
| A4 | `UserDefaults` is the correct persistence for `isCommunityShareEnabled` (not SwiftData or CloudKit KV store) | Architecture Patterns — Pattern 1 | If syncing the preference across devices is desired in future, SwiftData or iCloud KV store would be better. For this phase, local-only is consistent with D-07 opt-in behavior. |

---

## Open Questions

1. **CloudKit Console access timing**
   - What we know: CloudKit Console index setup is required before sorted leaderboard queries work.
   - What's unclear: When the developer runs the first build (Wave 1 task), the record type will be auto-created in development schema. Index setup must happen immediately after, before the fetch task is tested.
   - Recommendation: Add explicit Wave 0 task "Set up CloudKit development schema and indexes" as a prerequisite step with CloudKit Console instructions.

2. **LuckyDrawEntry count fetch for `contributionCount`**
   - What we know: `UserProfile` does not store total contribution count. `GamificationManager.monthlyLuckyDrawEntries` fetches monthly count only.
   - What's unclear: Should `SocialSyncManager` receive the all-time count as a parameter from the caller, or should it query SwiftData directly?
   - Recommendation: Pass as a parameter from `GamificationManager` after it fetches the all-time count via `FetchDescriptor<LuckyDrawEntry>()` (no predicate = all records). This keeps `SocialSyncManager` free of SwiftData dependency.

3. **Leaderboard result limit**
   - What we know: `resultsLimit` caps results; `CKQueryOperation.maximumResults` fetches all (potentially large).
   - What's unclear: How many active users in practice? A leaderboard of 100 is sensible for v1.
   - Recommendation: Default `resultsLimit: 100`. Do not implement pagination for Phase 12.

---

## Sources

### Primary (HIGH confidence)
- `refuel/Models.swift` — `UserProfile`, `LuckyDrawEntry` field inspection [VERIFIED: codebase read]
- `refuel/GamificationManager.swift` — sync hook points, XP award flow [VERIFIED: codebase read]
- `refuel/ContentViewModel.swift` — service injection pattern [VERIFIED: codebase read]
- `refuel/ProfileView.swift` — existing "Settings" and "Scout Network" sections, `.listStyle(.insetGrouped)` [VERIFIED: codebase read]
- `CLOUDKIT_SETUP.md` — container ID `iCloud.com.refuel.app`, entitlements confirmed [VERIFIED: codebase read]
- `.planning/codebase/ARCHITECTURE.md` — `@ModelActor`, `@Observable` patterns [VERIFIED: codebase read]
- `.planning/codebase/CONVENTIONS.md` — typography, naming, `final class` [VERIFIED: codebase read]
- `.planning/phases/12-global-community-sync/12-UI-SPEC.md` — component names, copywriting, interaction contract [VERIFIED: codebase read]

### Secondary (MEDIUM confidence)
- [fatbobman.com — Core Data with CloudKit: Synchronizing Public Database](https://fatbobman.com/en/posts/coredatawithcloudkit-5/) — public DB limitations: no custom zones, no tombstones, polling only, `isDeleted` workaround
- [swiftwithmajid.com — Getting Started with CloudKit](https://swiftwithmajid.com/2022/03/22/getting-started-with-cloudkit/) — `records(matching:)` async/await pattern
- [cocoacasts.com — Handling Account Status Changes](https://cocoacasts.com/handling-account-status-changes-with-cloudkit) — `CKAccountStatus` guard pattern
- [rambo.codes — CloudKit 101](https://www.rambo.codes/posts/2020-02-25-cloudkit-101) — save = create OR update with same recordID
- [superwall.com — CKSyncEngine](https://superwall.com/blog/syncing-data-with-cloudkit-in-your-ios-app-using-cksyncengine-and-swift-and-swiftui/) — CKSyncEngine does NOT support public DB
- [developer.apple.com — publicCloudDatabase](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase) — official API reference (content inaccessible via WebFetch due to JS gate; referenced from search results)
- [developer.apple.com — CKQuery sortDescriptors](https://developer.apple.com/documentation/cloudkit/ckquery/1413121-sortdescriptors) — sort descriptor API

### Tertiary (LOW confidence)
- Search result aggregations about CKRecord Sendability in Swift 6 — flagged as A2 in Assumptions Log

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — CloudKit is Apple's framework, same container as Phase 11, no third-party libs
- Architecture patterns: HIGH — derived directly from codebase patterns + well-documented CloudKit CRUD API
- Public DB limitations (no tombstones, no zones, no subscriptions): HIGH — consistent across multiple cited sources
- CKRecord async/await method signatures: MEDIUM — conceptually confirmed, exact iOS 18 Swift 6 overloads not verified against live Apple docs
- Pitfalls: HIGH — all pitfalls sourced from documented CloudKit behaviors

**Research date:** 2026-04-13
**Valid until:** 2026-07-13 (CloudKit API is stable; WWDC 2026 may introduce changes)
