---
phase: 12
slug: global-community-sync
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (native Xcode test target) |
| **Config file** | refuel.xcodeproj |
| **Quick run command** | `xcodebuild test -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:refuelTests 2>&1 | tail -20` |
| **Full suite command** | `xcodebuild test -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -40` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | — | — | Upsert uses deterministic record ID | unit | `xcodebuild test -scheme refuel -only-testing:refuelTests/SocialSyncManagerTests` | ❌ W0 | ⬜ pending |
| 12-01-02 | 01 | 1 | — | — | Privacy alias used, not real name | unit | `xcodebuild test -scheme refuel -only-testing:refuelTests/SocialSyncManagerTests` | ❌ W0 | ⬜ pending |
| 12-02-01 | 02 | 2 | — | — | Leaderboard query sorted by xp desc | manual | Build + simulator visual check | N/A | ⬜ pending |
| 12-02-02 | 02 | 2 | — | — | Opt-out removes record, hides from list | manual | Simulator interaction test | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `refuelTests/SocialSyncManagerTests.swift` — unit test stubs for upsert logic and alias generation
- [ ] Existing `refuelTests/` infrastructure already present — no new framework install needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Leaderboard renders sorted by XP | Phase 12 goal | CloudKit fetch requires live container; simulator can't mock public DB reads easily | Run on simulator with CloudKit dev environment; verify list order |
| Opt-out removes public record | Phase 12 goal | Requires live CloudKit delete + re-fetch cycle | Toggle opt-out in settings; verify user disappears from leaderboard after next sync |
| CloudKit Console index configured | Wave 0 gate | Manual console step; not automatable | Log into CloudKit Console, confirm Sortable index on `xp` field exists for `UserProfile` record type |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
