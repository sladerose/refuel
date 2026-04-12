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
    var isFavorite: Bool = false
    
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
            case .average: return Color(red: 1.0, green: 0.65, blue: 0.0) // Darker Amber for contrast
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
    
    @Relationship(deleteRule: .cascade, inverse: \RefuelEvent.station)
    var refuelLogs: [RefuelEvent] = []
    
    init(id: UUID = UUID(), name: String, address: String, latitude: Double, longitude: Double, openingHours: String? = nil, services: [String]? = nil, lastUpdated: Date? = nil, zScore: Double? = nil, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.openingHours = openingHours
        self.services = services
        self.lastUpdated = lastUpdated
        self.zScore = zScore
        self.isFavorite = isFavorite
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

@Model
final class RefuelEvent {
    @Attribute(.unique) var id: UUID
    var date: Date
    var amountInLitres: Double
    var pricePerLitre: Double
    var grade: String
    var stationName: String
    
    var station: Station?
    
    var totalCost: Double {
        amountInLitres * pricePerLitre
    }
    
    init(id: UUID = UUID(), date: Date = Date(), amountInLitres: Double, pricePerLitre: Double, grade: String, stationName: String, station: Station? = nil) {
        self.id = id
        self.date = date
        self.amountInLitres = amountInLitres
        self.pricePerLitre = pricePerLitre
        self.grade = grade
        self.stationName = stationName
        self.station = station
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var xp: Int
    var streakCount: Int
    var lastContributionDate: Date?
    var communityImpact: Double // Rand saved for others
    
    enum Rank: String, CaseIterable, Codable {
        case newcomer = "Newcomer"
        case activeMember = "Active Member"
        case reliableContributor = "Reliable Contributor"
        case expertScout = "Expert Scout"
        case fuelLegend = "Fuel Legend"
        
        var nextRankThreshold: Int? {
            switch self {
            case .newcomer: return 500
            case .activeMember: return 1000
            case .reliableContributor: return 2500
            case .expertScout: return 5000
            case .fuelLegend: return nil
            }
        }
    }
    
    var rank: Rank {
        if xp < 500 { return .newcomer }
        if xp < 1000 { return .activeMember }
        if xp < 2500 { return .reliableContributor }
        if xp < 5000 { return .expertScout }
        return .fuelLegend
    }
    
    init(id: UUID = UUID(), xp: Int = 0, streakCount: Int = 0, lastContributionDate: Date? = nil, communityImpact: Double = 0.0) {
        self.id = id
        self.xp = xp
        self.streakCount = streakCount
        self.lastContributionDate = lastContributionDate
        self.communityImpact = communityImpact
    }
}

@Model
final class LuckyDrawEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var stationName: String
    var contributionType: String // "scan" or "verify"
    
    init(id: UUID = UUID(), date: Date = Date(), stationName: String, contributionType: String) {
        self.id = id
        self.date = date
        self.stationName = stationName
        self.contributionType = contributionType
    }
}
