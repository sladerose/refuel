# CloudKit Setup Guide

To enable SwiftData to sync with CloudKit, you need to manually configure Xcode capabilities. This process requires an active Apple Developer account.

## Step 1: Add iCloud Capability

1. Open the project in Xcode (`refuel.xcodeproj` or `refuel.xcworkspace`).
2. Select the `refuel` project in the Project Navigator.
3. Select the `refuel` target under "TARGETS".
4. Go to the **Signing & Capabilities** tab.
5. Click the **+ Capability** button in the top left corner of the tab.
6. Search for **iCloud** and double-click to add it.
7. In the new iCloud section, check the box for **CloudKit**.
8. Under "Containers", click the **+** button.
9. Enter the custom container identifier: `iCloud.com.refuel.app` (or check it if it already appears in the list).

## Step 2: Add Background Modes Capability

1. Still in the **Signing & Capabilities** tab, click the **+ Capability** button again.
2. Search for **Background Modes** and double-click to add it.
3. In the new Background Modes section, check the box for **Remote notifications**.
   - *Why?* CloudKit uses silent remote notifications to inform the app when data changes in the cloud so it can fetch the updates.

## Step 3: Verify Model Configuration

Ensure that your `ModelConfiguration` in `refuelApp.swift` has CloudKit sync enabled:
```swift
let schema = Schema([
    RefuelEvent.self,
    Vehicle.self
])
let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
```

## Step 4: Testing Sync

1. Build and run the app on a physical device or Simulator (Device A) logged into your Apple ID.
2. Create some data (e.g., add a vehicle or a refuel event).
3. Build and run the app on a second device or Simulator (Device B) logged into the *same* Apple ID.
4. Verify that the data created on Device A appears on Device B. Note that sync might take a few moments.

*Note: For the best testing experience, use physical devices as Simulator push notifications (required for immediate background sync) can sometimes be unreliable.*
