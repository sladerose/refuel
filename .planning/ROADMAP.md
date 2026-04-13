# Roadmap: Refuel

## Phases

- [x] **Phase 1: Core Map & Location Infrastructure** - Foundation for spatial UI, user location tracking, and external navigation. (completed 2026-04-11)
- [x] **Phase 2: Price Integration & Persistence** - External API integration, SwiftData persistence, and sortable list discovery. (completed 2026-04-11)
- [x] **Phase 3: Value Analytics & Dynamic Discovery** - RAG status logic, price comparisons, and geofence-triggered refreshes. (completed 2026-04-12)
- [x] **Phase 4: Personalization & Cost Tracking** - Favorite stations management and refuel history logging. (completed 2026-04-12)
- [x] **Phase 5: Project Polish & Final Verification** - Closing feature gaps, navigation wiring, and detailed information rendering. (completed 2026-04-12)
- [x] **Phase 6: The Vision System** - OCR for fuel receipts and price board recognition using VisionKit. (completed 2026-04-12)
- [x] **Phase 7: The Engagement Engine** - Gamification layer including streaks, XP, ranks, and user profiles. (completed 2026-04-12)
- [x] **Phase 8: Proactive Intelligence** - Dwell detection, proactive verifications, and CEF predictive hike alerts. (completed 2026-04-12)
- [x] **Phase 9: Rewards Hub & Social Proof** - Lucky Draw system, sharing stats, and community impact visualization. (completed 2026-04-12)
- [x] **Milestone: Architecture & UI Refactor** - MVVM deconstruction, Liquid Glass UI standardization, and OCR 2.0. (completed 2026-04-12)

- [x] **Phase 11: The Cloud Foundation** - Resolve Xcode entitlement blockers and fully activate CloudKit for SwiftData syncing. (completed 2026-04-13)
- [ ] **Phase 12: Global Community Sync** - Enable users to share contributions with the broader community via public CloudKit database and leaderboard.
- [ ] **Phase 13: Live Data Ingestion & Alerts** - Connect to live external data and push critical fuel hike alerts to users.
- [ ] **Phase 14: Station Verification Crowdsourcing** - Use community input to maintain accurate station metadata via consensus voting.

### Phase 12: Global Community Sync

**Goal:** Enable users to share their contributions with the broader community via CloudKit public database and global leaderboard.

**Plans:** 3 plans

Plans:
- [ ] 12-01-PLAN.md — SocialSyncManager CloudKit engine + UserProfile.communityAlias + GamificationManager sync hook + Wave 0 test stubs
- [ ] 12-02-PLAN.md — LeaderboardView + LeaderboardRowView — all 9 UI states (loading, empty, error, sharing-off, You row, sticky footer)
- [ ] 12-03-PLAN.md — ProfileView opt-in toggle (CommunitySyncSettingsRow) + leaderboard nav entry + environment wiring

### Phase 13: Live Data Ingestion & Alerts

**Goal:** Connect to live external data and push critical fuel hike alerts to users.

**Plans:** 3 plans

Plans:
- [ ] 13-01-PLAN.md — UserDefaults prefs extension + FuelPriceSyncService live URLSession + HikeDetector + unit tests (TDD)
- [ ] 13-02-PLAN.md — ProactiveService calendar logic removal + HikeAlertBanner Bool-driven refactor
- [ ] 13-03-PLAN.md — refuelApp.swift BGAppRefreshTask wiring + Secrets.xcconfig + ProfileView region/grade pickers

### Phase 14: Station Verification Crowdsourcing

**Goal:** Use community input to maintain accurate station metadata via consensus voting.

**Tasks:**
- Extend `PriceVerificationView` to flag incorrect station metadata
- Submit verifications to public CloudKit database for consensus voting
- Reward users with bonus XP for confirmed metadata corrections

## Progress Table

| Milestone | Tasks | Status | Date |
|-----------|-------|--------|------|
| 1. Foundation | 3/3 | Complete | 2026-04-11 |
| 2. Integration | 2/2 | Complete | 2026-04-12 |
| 3. Analytics | 2/2 | Complete | 2026-04-12 |
| 4. Personalization | 2/2 | Complete | 2026-04-12 |
| 5. Polish | 2/2 | Complete | 2026-04-12 |
| 6. Vision System | 2/2 | Complete | 2026-04-12 |
| 7. Engagement Engine | 1/1 | Complete | 2026-04-12 |
| 8. Proactive Intelligence | 1/1 | Complete | 2026-04-12 |
| 9. Rewards & Social | 1/1 | Complete | 2026-04-12 |
| 10. Architecture & UI | 3/3 | Complete | 2026-04-12 |
