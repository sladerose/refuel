import Foundation
import SwiftData

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
    
    @Relationship(deleteRule: .cascade, inverse: \FuelPrice.station)
    var prices: [FuelPrice] = []
    
    init(id: UUID = UUID(), name: String, address: String, latitude: Double, longitude: Double, openingHours: String? = nil, services: [String]? = nil, lastUpdated: Date? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.openingHours = openingHours
        self.services = services
        self.lastUpdated = lastUpdated
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
