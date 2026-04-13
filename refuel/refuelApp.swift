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
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Station.self,
            FuelPrice.self,
            RefuelEvent.self,
            UserProfile.self,
            LuckyDrawEntry.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: Self.sharedModelContainer)
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
