import Foundation

struct StationDTO: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let openingHours: String?
    let services: [String]?
    let prices: [FuelPriceDTO]
}

struct FuelPriceDTO: Identifiable {
    let id: UUID
    let grade: String
    let price: Double
}

protocol FuelPriceService {
    func fetchNearbyStations(latitude: Double, longitude: Double) async throws -> [StationDTO]
}

class MockFuelPriceService: FuelPriceService {
    func fetchNearbyStations(latitude: Double, longitude: Double) async throws -> [StationDTO] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        return [
            StationDTO(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                name: "Mobil Central",
                address: "123 Main St",
                latitude: latitude + 0.01,
                longitude: longitude + 0.01,
                openingHours: "24/7",
                services: ["Cafe", "Car Wash"],
                prices: [
                    FuelPriceDTO(id: UUID(), grade: "91", price: 2.85),
                    FuelPriceDTO(id: UUID(), grade: "95", price: 3.05),
                    FuelPriceDTO(id: UUID(), grade: "Diesel", price: 2.15)
                ]
            ),
            StationDTO(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                name: "Z Station North",
                address: "456 North Rd",
                latitude: latitude - 0.015,
                longitude: longitude + 0.005,
                openingHours: "6am - 10pm",
                services: ["Cafe"],
                prices: [
                    FuelPriceDTO(id: UUID(), grade: "91", price: 2.82),
                    FuelPriceDTO(id: UUID(), grade: "95", price: 3.02),
                    FuelPriceDTO(id: UUID(), grade: "Diesel", price: 2.12)
                ]
            ),
            StationDTO(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                name: "BP Express West",
                address: "789 West Ave",
                latitude: latitude + 0.005,
                longitude: longitude - 0.012,
                openingHours: "24/7",
                services: ["Car Wash"],
                prices: [
                    FuelPriceDTO(id: UUID(), grade: "91", price: 2.88),
                    FuelPriceDTO(id: UUID(), grade: "95", price: 3.08),
                    FuelPriceDTO(id: UUID(), grade: "Diesel", price: 2.18)
                ]
            )
        ]
    }
}
