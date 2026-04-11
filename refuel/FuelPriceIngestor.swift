import Foundation
import SwiftData

@ModelActor
actor FuelPriceIngestor {
    func updatePrices(latitude: Double, longitude: Double, service: FuelPriceService) async throws {
        let dtos = try await service.fetchNearbyStations(latitude: latitude, longitude: longitude)
        
        for dto in dtos {
            let id = dto.id
            let fetchDescriptor = FetchDescriptor<Station>(predicate: #Predicate { $0.id == id })
            let stations = try modelContext.fetch(fetchDescriptor)
            
            let station: Station
            if let existing = stations.first {
                station = existing
                // Update attributes
                station.name = dto.name
                station.address = dto.address
                station.latitude = dto.latitude
                station.longitude = dto.longitude
                station.openingHours = dto.openingHours
                station.services = dto.services
                station.lastUpdated = Date()
            } else {
                station = Station(
                    id: dto.id,
                    name: dto.name,
                    address: dto.address,
                    latitude: dto.latitude,
                    longitude: dto.longitude,
                    openingHours: dto.openingHours,
                    services: dto.services,
                    lastUpdated: Date()
                )
                modelContext.insert(station)
            }
            
            // Handle prices: Remove old ones and insert new ones
            // NOTE: In a real app, you might want to match grades to preserve IDs if needed.
            // But for simple prices, replacing is often fine.
            let oldPrices = station.prices
            for oldPrice in oldPrices {
                modelContext.delete(oldPrice)
            }
            
            for priceDTO in dto.prices {
                let newPrice = FuelPrice(grade: priceDTO.grade, price: priceDTO.price, timestamp: Date(), station: station)
                modelContext.insert(newPrice)
            }
        }
        
        try modelContext.save()
    }
}
