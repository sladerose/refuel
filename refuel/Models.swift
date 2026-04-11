import Foundation
import SwiftData
import SwiftUI

@Model
final class Station {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var openingHours: String?
    var services: [String]?
    var lastUpdated: Date?
    var zScore: Double?
    
    enum RAGStatus: String, Codable, CaseIterable {
        case exceptional
        case good
        case average
        case expensive
        case avoid
        
        var color: Color {
            switch self {
            case .exceptional: return Color(red: 0, green: 0.5, blue: 0) // Dark Green
            case .good: return .green
            case .average: return .yellow
            case .expensive: return .orange
            case .avoid: return .red
            }
        }
    }
    
    var ragStatus: RAGStatus {
        guard let z = zScore else { return .average }
        if z < -1.5 { return .exceptional }
        if z < -0.5 { return .good }
        if z <= 0.5 { return .average }
        if z <= 1.5 { return .expensive }
        return .avoid
    }
    
    var isStale: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        let fourHours: TimeInterval = 4 * 60 * 60
        return Date().timeIntervalSince(lastUpdated) > fourHours
    }
    
    @Relationship(deleteRule: .cascade, inverse: \FuelPrice.station)
    var prices: [FuelPrice] = []
    
    init(id: UUID = UUID(), name: String, address: String, latitude: Double, longitude: Double, openingHours: String? = nil, services: [String]? = nil, lastUpdated: Date? = nil, zScore: Double? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.openingHours = openingHours
        self.services = services
        self.lastUpdated = lastUpdated
        self.zScore = zScore
    }
}

@Model
final class FuelPrice {
    @Attribute(.unique) var id: UUID
    var grade: String // e.g., "91", "95", "Diesel"
    var price: Double
    var timestamp: Date
    
    var station: Station?
    
    init(id: UUID = UUID(), grade: String, price: Double, timestamp: Date = Date(), station: Station? = nil) {
        self.id = id
        self.grade = grade
        self.price = price
        self.timestamp = timestamp
        self.station = station
    }
}
