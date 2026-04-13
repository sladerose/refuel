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
        
        // Specific Amanzimtoti / Kingsburgh stations with user-provided precise coordinates
        return [
            StationDTO(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                name: "BP",
                address: "26 Seadoone Road, Amanzimtoti",
                latitude: -30.066488,
                longitude: 30.869853,
                openingHours: "Open 24 hrs",
                services: ["Wild Bean Cafe", "BP Ultimate", "Car Wash"],
                prices: [
                    FuelPriceDTO(id: UUID(), grade: "91", price: 23.45),
                    FuelPriceDTO(id: UUID(), grade: "95", price: 24.12),
                    FuelPriceDTO(id: UUID(), grade: "Diesel", price: 21.85)
                ]
            ),
            StationDTO(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                name: "Engen",
                address: "34 Rockview Road, Amanzimtoti",
                latitude: -30.064961,
                longitude: 30.878491,
                openingHours: "Open 24 hrs",
                services: ["QuickShop", "Wimpy", "Eco-Drive Diesel"],
                prices: [
                    FuelPriceDTO(id: UUID(), grade: "91", price: 23.42),
                    FuelPriceDTO(id: UUID(), grade: "95", price: 24.08),
                    FuelPriceDTO(id: UUID(), grade: "Diesel", price: 21.80)
                ]
            ),
            StationDTO(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                name: "Total",
                address: "2 Gus Brown Road, Kingsburgh",
                latitude: -30.077796,
                longitude: 30.868594,
                openingHours: "24/7",
                services: ["Bonjour Cafe", "Total Excellium"],
                prices: [
                    FuelPriceDTO(id: UUID(), grade: "91", price: 23.48),
                    FuelPriceDTO(id: UUID(), grade: "95", price: 24.15),
                    FuelPriceDTO(id: UUID(), grade: "Diesel", price: 21.88)
                ]
            )
        ]
    }
}
