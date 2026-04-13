# Phase 12: Global Community Sync - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Enable users to share their contributions with the broader community via CloudKit's public database. Sync LuckyDrawEntry records (as aggregate stats) and UserProfile impact data. Surface a global leaderboard showing top XP contributors. This phase covers the sync infrastructure and leaderboard view only — crowdsourced price verification and station metadata are Phase 14.

</domain>

<decisions>
## Implementation Decisions

### User Identity on the Leaderboard
- **D-01:** Auto-generated alias format: `Scout#XXXX` where XXXX is derived from the user's UUID (e.g., first 4 hex chars). No user-set display names — no onboarding step required.
- **D-02:** "You" marker on the leaderboard row — user always sees their own position regardless of rank.

### Leaderboard Scope
- **D-03:** Global leaderboard — all users worldwide, no geographic filter. "In the area" from the roadmap is overridden by this decision.

### What Gets Synced to Public CloudKit DB
- **D-04:** Aggregate stats only — one CKRecord per user containing: alias, xp, rank, communityImpact, total contribution count (scans + verifies). No individual LuckyDrawEntry records synced publicly.
- **D-05:** Sync is triggered on significant events (XP gain, new contribution) — not on every app launch.

### Leaderboard Ranking Metric
- **D-06 (Claude's Discretion):** XP is the ranking metric. Rationale: already computed, tied to all contribution types (scan, verify, streak), and consistent with the existing rank system (Newcomer → Fuel Legend). Users already understand XP as the primary progression metric.

### Privacy & Opt-In
- **D-07:** Opt-in only. User must explicitly enable community sharing in settings before any data is written to the public CloudKit database. Default: off. No data leaves the private DB until the user enables this.
- **D-08:** If the user opts out after previously opting in, their public CKRecord is deleted.

### Claude's Discretion
- Leaderboard UI placement (recommend: tab in existing Rewards Hub / Phase 9 ProfileView area)
- CKRecord schema design and field names
- Exact sync trigger logic and debounce strategy
- Empty leaderboard state (when no community members have opted in yet)
- Error handling for CloudKit public DB failures

</decisions>

<specifics>
## Specific Ideas

- No specific references given — implementation follows existing app patterns (Liquid Glass UI, system text styles, @ModelActor for background ops).

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing models and gamification logic
- `refuel/Models.swift` — `UserProfile` (xp, rank, communityImpact, streakCount) and `LuckyDrawEntry` (date, stationName, contributionType) — these are the source of truth for what gets synced
- `refuel/GamificationManager.swift` — how XP is awarded and LuckyDrawEntry records are created; sync should hook into these events
- `refuel/refuelApp.swift` — ModelContainer schema registration; new models must be added here

### CloudKit private DB (Phase 11 reference)
- `CLOUDKIT_SETUP.md` — CloudKit container ID (`iCloud.com.refuel.app`), capability setup; public DB uses the same container

### UI and architecture patterns
- `.planning/codebase/ARCHITECTURE.md` — @ModelActor pattern for background CloudKit ops, @Observable for service layer
- `.planning/codebase/CONVENTIONS.md` — naming conventions for new files

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UserProfile` model — contains all fields needed for the public sync record (xp, communityImpact, rank). Add a `communityAlias` computed property or store it.
- `GamificationManager` — natural hook point for triggering sync after XP awards or new entries.
- `ProfileView.swift` / `GamificationViews.swift` — existing rewards UI; leaderboard should live here or alongside.

### Established Patterns
- `@ModelActor` for background data operations — use this for CloudKit public DB writes.
- `@Observable` service class — `SocialSyncManager` should follow this pattern.
- Liquid Glass UI / system text styles — leaderboard view must use `.title`, `.headline`, etc. (no fixed point sizes).

### Integration Points
- `refuelApp.swift` `sharedModelContainer` — register any new SwiftData models here.
- `GamificationManager.createLuckyDrawEntry()` and XP award functions — sync triggers attach here.
- Rewards/Profile tab in ContentView — leaderboard entry point.

</code_context>

<deferred>
## Deferred Ideas

- Per-area leaderboard (city/suburb scoped) — revisit in a future phase if global leaderboard has low engagement.
- Social following / seeing friends' rankings specifically — post-v3 social layer.
- Public LuckyDrawEntry history (individual contributions visible) — privacy risk, deferred indefinitely.

</deferred>

---

*Phase: 12-global-community-sync*
*Context gathered: 2026-04-13*
