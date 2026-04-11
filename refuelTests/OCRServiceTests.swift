import Testing
import Foundation
import SwiftData
@testable import refuel

@MainActor
struct OCRServiceTests {
    let ocrService = OCRService.shared
    
    @Test func testReceiptParsing() async throws {
        let stations = [
            Station(name: "Shell", address: "123 Road", latitude: 0, longitude: 0),
            Station(name: "BP", address: "456 Road", latitude: 0, longitude: 0)
        ]
        
        let lines = [
            "SHELL BRIGHTON",
            "123 BRIGHTON ROAD",
            "DATE: 2026-04-11",
            "PUMP 04",
            "UNLEADED 91",
            "QTY: 45.67 L",
            "PRICE: 2.15 $/L",
            "TOTAL: $98.19",
            "THANK YOU"
        ]
        
        // This is a dummy call to the private/internal method.
        // I'll need to make parseText internal.
        let data = ocrService.parseText(lines, stations: stations)
        
        #expect(data.stationName == "Shell")
        #expect(data.amountInLitres == 45.67)
        #expect(data.totalCost == 98.19)
        #expect(data.grade == "91")
        // #expect(data.pricePerLitre == 2.15) // Future enhancement
    }
}
