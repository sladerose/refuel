import Foundation
import SwiftData
import Accelerate

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
            let oldPrices = station.prices ?? []
            for oldPrice in oldPrices {
                modelContext.delete(oldPrice)
            }
            
            for priceDTO in dto.prices {
                let newPrice = FuelPrice(grade: priceDTO.grade, price: priceDTO.price, timestamp: Date(), station: station)
                modelContext.insert(newPrice)
            }
        }
        
        // Recalculate analytics for all stations after updating prices
        let fetchDescriptor = FetchDescriptor<Station>()
        let allStations = try modelContext.fetch(fetchDescriptor)
        Self.calculateAnalytics(for: allStations)
        
        try modelContext.save()
    }
    
    static func calculateAnalytics(for stations: [Station]) {
        // Only consider stations with prices and non-zero prices
        let validData = stations.compactMap { station -> (Station, Double)? in
            guard let minPrice = (station.prices ?? []).compactMap({ $0.price }).min(), minPrice > 0 else {
                return nil
            }
            return (station, minPrice)
        }
        
        // Reset zScore for stations without valid prices
        let validStationIds = Set(validData.map { $0.0.id })
        for station in stations {
            if !validStationIds.contains(station.id) {
                station.zScore = nil
            }
        }
        
        guard validData.count >= 1 else { return }
        
        if validData.count == 1 {
            validData[0].0.zScore = 0
            return
        }
        
        let prices = validData.map { $0.1 }
        let n = vDSP_Length(prices.count)
        
        var mean = 0.0
        vDSP_meanvD(prices, 1, &mean, n)
        
        var variance = 0.0
        var negativeMean = -mean
        var differences = [Double](repeating: 0.0, count: prices.count)
        vDSP_vsaddD(prices, 1, &negativeMean, &differences, 1, n)
        
        var squaredDifferences = [Double](repeating: 0.0, count: prices.count)
        vDSP_vsqD(differences, 1, &squaredDifferences, 1, n)
        vDSP_meanvD(squaredDifferences, 1, &variance, n)
        
        let stdDev = sqrt(variance)
        
        if stdDev == 0 {
            for (station, _) in validData {
                station.zScore = 0
            }
        } else {
            for (station, minPrice) in validData {
                station.zScore = (minPrice - mean) / stdDev
            }
        }
    }
}
