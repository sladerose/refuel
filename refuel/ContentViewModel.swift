//
//  ContentViewModel.swift
//  refuel
//
//  Created by slade on 2026/04/12.
//

import SwiftUI
import SwiftData
import CoreLocation

@Observable
@MainActor
class ContentViewModel {
    var locationManager = LocationManager()
    var searchService = SearchService()
    var geofenceService = GeofenceService()
    var gamificationManager: GamificationManager
    var notificationManager = NotificationManager()
    var proactiveService: ProactiveService
    
    var isRefreshing = false
    
    init(modelContainer: ModelContainer) {
        let gManager = GamificationManager(modelContainer: modelContainer)
        self.gamificationManager = gManager
        
        let gService = GeofenceService()
        self.geofenceService = gService
        
        let nManager = NotificationManager()
        self.notificationManager = nManager
        
        self.proactiveService = ProactiveService(geofenceService: gService, notificationManager: nManager, modelContainer: modelContainer)
    }
    
    func refreshPrices(modelContext: ModelContext, stations: [Station]) async {
        guard let location = locationManager.userLocation, !isRefreshing else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        let ingestor = FuelPriceIngestor(modelContainer: modelContext.container)
        let service = MockFuelPriceService()
        
        do {
            try await ingestor.updatePrices(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                service: service
            )
            
            // Re-establish geofence at new location
            geofenceService.monitorRegion(
                center: location.coordinate,
                radius: 5000, // 5km
                identifier: "current_search"
            )
            
            // Start monitoring nearby stations for dwell detection
            for station in stations {
                geofenceService.monitorStation(id: station.id, latitude: station.latitude, longitude: station.longitude)
            }
        } catch {
            print("Failed to refresh prices: \(error)")
        }
    }
    
    func shouldRefresh(stations: [Station]) -> Bool {
        stations.isEmpty || stations.contains(where: { $0.isStale })
    }
}
