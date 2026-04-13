import Foundation
import SwiftData

struct FuelSADTO: Codable {
    let status: String
    let data: FuelPricesData
}

struct FuelPricesData: Codable {
    let petrol95_coastal: Double
    let petrol95_inland: Double
    let diesel50ppm_coastal: Double
    let diesel50ppm_inland: Double
    let last_updated: String
    
    enum CodingKeys: String, CodingKey {
        case petrol95_coastal = "p95_c"
        case petrol95_inland = "p95_i"
        case diesel50ppm_coastal = "d50_c"
        case diesel50ppm_inland = "d50_i"
        case last_updated = "updated_at"
    }
}

@ModelActor
actor FuelPriceSyncService {
    private let apiKey = "YOUR_API_KEY_HERE" // Should be moved to Config/Environment
    private let baseURL = "https://api.fuelsa.co.za/exapi/fuel/current"
    
    func syncLatestPrices() async throws {
        // 1. Fetch from API
        // Note: In a real app, use URLSession with the API Key header
        // For this implementation, we simulate the fetch logic
        
        /* 
        var request = URLRequest(url: URL(string: baseURL)!)
        request.addValue(apiKey, forHTTPHeaderField: "key")
        let (data, _) = try await URLSession.shared.data(for: request)
        let dto = try JSONDecoder().decode(FuelSADTO.self, from: data)
        */
        
        // Simulated update logic for the purpose of the prototype
        // In a production app, we would map the DTO to our Station models
        // to update the global benchmark or specific "Virtual" stations representing the average.
        
        let fetchDescriptor = FetchDescriptor<Station>()
        let stations = try modelContext.fetch(fetchDescriptor)
        
        // For each station, we could potentially update its prices if it matches the region,
        // but typically we use this for the Z-score calculation baseline.
        
        // Re-run analytics to ensure z-scores are fresh
        FuelPriceIngestor.calculateAnalytics(for: stations)
        
        try modelContext.save()
    }
}
