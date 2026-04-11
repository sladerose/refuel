//
//  refuelApp.swift
//  refuel
//
//  Created by slade on 2026/04/11.
//

import SwiftUI
import SwiftData

@main
struct refuelApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Station.self,
            FuelPrice.self,
            RefuelEvent.self,
            UserProfile.self,
            LotteryEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: sharedModelContainer)
        }
        .modelContainer(sharedModelContainer)
    }
}
