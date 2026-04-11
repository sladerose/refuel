import Testing
import SwiftData
import Foundation
@testable import refuel

@MainActor
struct ValueAnalyticsTests {
    var modelContainer: ModelContainer!

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: Station.self, configurations: config)
    }

    @Test func testZScoreCalculation() async throws {
        let context = modelContainer.mainContext
        
        let s1 = Station(name: "S1", address: "A1", latitude: 0, longitude: 0)
        let p1 = FuelPrice(grade: "91", price: 1.0, station: s1)
        s1.prices.append(p1)
        
        let s2 = Station(name: "S2", address: "A2", latitude: 0, longitude: 0)
        let p2 = FuelPrice(grade: "91", price: 2.0, station: s2)
        s2.prices.append(p2)
        
        let s3 = Station(name: "S3", address: "A3", latitude: 0, longitude: 0)
        let p3 = FuelPrice(grade: "91", price: 3.0, station: s3)
        s3.prices.append(p3)
        
        context.insert(s1)
        context.insert(s2)
        context.insert(s3)
        
        FuelPriceIngestor.calculateAnalytics(for: [s1, s2, s3])
        
        // Mean = (1+2+3)/3 = 2
        // Variance = ((1-2)^2 + (2-2)^2 + (3-2)^2) / 3 = (1 + 0 + 1) / 3 = 0.666...
        // stdDev = sqrt(0.666...) = 0.816496580927726
        
        // s1: (1-2)/0.816496580927726 = -1.224744871391589
        // s2: (2-2)/0.816496580927726 = 0
        // s3: (3-2)/0.816496580927726 = 1.224744871391589
        
        #expect(s1.zScore != nil)
        #expect(s2.zScore != nil)
        #expect(s3.zScore != nil)
        
        #expect(abs(s1.zScore! - (-1.224744871391589)) < 0.0001)
        #expect(abs(s2.zScore! - 0.0) < 0.0001)
        #expect(abs(s3.zScore! - 1.224744871391589) < 0.0001)
    }
    
    @Test func testRAGStatusMapping() async throws {
        let s1 = Station(name: "S1", address: "A1", latitude: 0, longitude: 0, zScore: -2.0)
        #expect(s1.ragStatus == .exceptional)
        
        let s2 = Station(name: "S2", address: "A2", latitude: 0, longitude: 0, zScore: -1.0)
        #expect(s2.ragStatus == .good)
        
        let s3 = Station(name: "S3", address: "A3", latitude: 0, longitude: 0, zScore: 0.0)
        #expect(s3.ragStatus == .average)
        
        let s4 = Station(name: "S4", address: "A4", latitude: 0, longitude: 0, zScore: 1.0)
        #expect(s4.ragStatus == .expensive)
        
        let s5 = Station(name: "S5", address: "A5", latitude: 0, longitude: 0, zScore: 2.0)
        #expect(s5.ragStatus == .avoid)
    }
}
