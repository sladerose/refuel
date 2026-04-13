---
phase: 13
slug: live-data-ingestion-alerts
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`) |
| **Config file** | Xcode scheme (no external config file) |
| **Quick run command** | `xcodebuild test -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:refuelTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -scheme refuel -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |
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
| 13-01-01 | 01 | 1 | D-08/D-09 | API key in source control | Key never hardcoded in Swift; `Bundle.main.infoDictionary` lookup | unit | `xcodebuild test ... -only-testing:refuelTests` | ❌ W0 | ⬜ pending |
| 13-01-02 | 01 | 1 | D-10 | — | N/A | unit | `xcodebuild test ... -only-testing:refuelTests/FuelPriceSyncTests` | ❌ W0 | ⬜ pending |
| 13-01-03 | 01 | 1 | D-12 | Duplicate alert | Duplicate alert guard prevents re-fire | unit | `xcodebuild test ... -only-testing:refuelTests/FuelPriceSyncTests` | ❌ W0 | ⬜ pending |
| 13-01-04 | 01 | 1 | D-04/D-05/D-06/D-07 | — | N/A | unit | `xcodebuild test ... -only-testing:refuelTests/PreferenceDefaultsTests` | ❌ W0 | ⬜ pending |
| 13-02-01 | 02 | 2 | D-10/D-11 | — | Silent fail logged via OSLog | manual | Xcode debugger simulate command | ✅ existing | ⬜ pending |
| 13-03-01 | 03 | 3 | D-04/D-06 | — | N/A | manual | UI inspection | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `refuelTests/FuelPriceSyncTests.swift` — unit tests for price comparison logic (D-01, D-10) and duplicate-alert guard (D-12)
- [ ] `refuelTests/PreferenceDefaultsTests.swift` — unit tests for UserDefaults extension property defaults (D-05, D-07)

*Pattern: reuse `ValueAnalyticsTests.swift` — `@MainActor` struct, in-memory `ModelContainer`*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| BGAppRefreshTask delivery and execution | D-10 | Not automatable in CI; simulators have unreliable background task support | Background app, then run in Xcode console: `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.slade.refuel.price-sync"]` |
| Notification banner appears on price hike | D-10 | UNUserNotificationCenter requires device/simulator with notifications enabled | Trigger background task simulate command; confirm notification banner appears |
| Region/grade pickers visible in Settings | D-04/D-06 | UI inspection | Open app → Profile tab → Settings section; confirm Coastal/Inland and Petrol 95/Diesel 50ppm pickers present |
| No notification if auth not granted | D-11 | Requires device permission state manipulation | Revoke notification permission in Settings → run task simulate → confirm no notification and OSLog entry present |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
