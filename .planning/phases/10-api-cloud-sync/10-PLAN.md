# Phase 10: API & Cloud Sync

**Goal**: Transition to a cloud-synced ecosystem with real-time fuel price updates.

## 10-01-PLAN.md: CloudKit Foundation & Private Sync
**Objective**: Enable iCloud syncing for personal data using SwiftData + CloudKit.
- **Task 1**: Enable CloudKit capabilities in Xcode and configure the `iCloud.com.refuel.app` container. Ensure "Remote notifications" and "Background fetch" are enabled. (Note: This is a manual check in the Xcode project settings.)
- **Task 2**: Modify `Station`, `FuelPrice`, `RefuelEvent`, and `UserProfile` models in `Models.swift` to ensure compatibility with CloudKit (no unique attributes, all relationships optional, non-optional attributes have default values).
- **Task 3**: Update `refuelApp.swift` to use `NSPersistentCloudKitContainerOptions` with the private database for SwiftData.

## 10-02-PLAN.md: Background Sync & Public Social Layer
**Objective**: Implement real-time price ingestion and cross-user social sharing.
- **Task 1**: Create `FuelPriceSyncService` using a `ModelActor` to ingest data from Fuel SA API in the background. Register a `BGAppRefreshTask` for periodic updates.
- **Task 2**: Implement `SocialSyncManager` using the CloudKit framework (CKContainer.publicCloudDatabase) to share `LuckyDrawEntry` records globally.
- **Task 3**: Update `ProfileView` and `ContentViewModel` to include a `SyncStatus` indicator (Cloud icon with 'Synced' or 'Syncing...' states) and handle account status changes.
