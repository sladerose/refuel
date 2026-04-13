# Roadmap: Refuel vNext (v3)

## Objective
Following the successful completion of the v1 and v2 phases (Core Map, Value Analytics, Engagement Engine, Vision System, and UI Standardization), the v3 roadmap shifts focus toward fully enabling real-time cloud data, cross-user social interactions, and comprehensive ecosystem intelligence.

## Phases

- [x] **Phase 11: The Cloud Foundation** *(completed 2026-04-13)*
  - **Goal:** Resolve Xcode entitlement blockers and fully activate CloudKit.
  - **Plans:** 1 plans
    - [x] 11-01-PLAN.md — Resolve Xcode entitlement blockers and fully activate CloudKit for SwiftData syncing.
  - **Tasks:**
    - [x] Document exact manual Xcode setup steps for developers (iCloud, Background Modes).
    - [x] Restore the `cloudKitDatabase` configuration in `refuelApp.swift`.
    - [x] Validate end-to-end sync of personal data (Favorites, Refuel History) across multiple devices using the `iCloud.com.refuel.app` private database.

- [ ] **Phase 12: Global Community Sync**
  - **Goal:** Enable users to share their contributions with the broader community.
  - **Tasks:**
    - Implement `SocialSyncManager` using `CKContainer.default().publicCloudDatabase`.
    - Sync `LuckyDrawEntry` records and anonymous `UserProfile` impact stats to the public database.
    - Create a global leaderboard view for top contributors in the area.

- [ ] **Phase 13: Live Data Ingestion & Alerts**
  - **Goal:** Connect to live external data and push critical updates to users.
  - **Tasks:**
    - Fully integrate `FuelPriceSyncService` with the production Fuel SA API (or similar provider).
    - Implement `BGAppRefreshTask` for reliable background data ingestion.
    - Set up predictive Push Notifications (via CloudKit subscriptions or local triggers) to alert users 24 hours before a confirmed national fuel price hike.

- [ ] **Phase 14: Station Verification Crowdsourcing**
  - **Goal:** Use community input to maintain accurate station metadata.
  - **Tasks:**
    - Extend `PriceVerificationView` to allow users to flag incorrect station locations, missing fuel grades, or updated opening hours.
    - Submit these verifications to the public CloudKit database for consensus voting.
    - Reward users with bonus XP for confirmed metadata corrections.

## Future Horizons (Post-v3)
- Advanced vehicle telemetry (OBD2 integration) to calculate precise real-world fuel economy.
- Integration with third-party payment providers to allow in-app fuel purchases.
- Cross-platform support (Android/Kotlin Multiplatform).

---
*Roadmap generated on 2026-04-13 following v2 completion.*