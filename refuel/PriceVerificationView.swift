import SwiftUI
import SwiftData

struct PriceVerificationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(GamificationManager.self) private var gamificationManager
    
    let station: Station
    @State private var editedPrices: [PriceEntry]
    
    struct PriceEntry: Identifiable {
        let id = UUID()
        let grade: String
        var price: Double
    }
    
    init(station: Station, detectedPrices: [String: Double]) {
        self.station = station
        
        // Initialize with detected prices, matching existing grades if possible
        var entries = [PriceEntry]()
        for (grade, price) in detectedPrices {
            entries.append(PriceEntry(grade: grade, price: price))
        }
        
        // If no prices detected, show existing station prices for editing
        if entries.isEmpty {
            for fuelPrice in station.prices {
                entries.append(PriceEntry(grade: fuelPrice.grade, price: fuelPrice.price))
            }
        }
        
        _editedPrices = State(initialValue: entries)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Detected Prices for \(station.name)")) {
                    if editedPrices.isEmpty {
                        Text("No prices detected. Please add manually.")
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach($editedPrices) { $entry in
                        HStack {
                            Text(entry.grade)
                                .font(.headline)
                            Spacer()
                            TextField("Price", value: $entry.price, format: .currency(code: "ZAR"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }
                    .onDelete { indexSet in
                        editedPrices.remove(atOffsets: indexSet)
                    }
                }
                
                Section {
                    Button(action: {
                        editedPrices.append(PriceEntry(grade: "95", price: 0.0))
                    }) {
                        Label("Add Grade", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Verify Prices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        savePrices()
                        dismiss()
                    }
                    .disabled(editedPrices.isEmpty)
                }
            }
        }
    }
    
    private func savePrices() {
        for entry in editedPrices {
            if let existingPrice = station.prices.first(where: { $0.grade == entry.grade }) {
                existingPrice.price = entry.price
                existingPrice.timestamp = Date()
            } else {
                let newPrice = FuelPrice(grade: entry.grade, price: entry.price, timestamp: Date(), station: station)
                modelContext.insert(newPrice)
            }
        }
        
        station.lastUpdated = Date()
        
        // Award XP for verification
        gamificationManager.awardXP(amount: 10, stationName: station.name, type: "verify")
        
        // Re-run analytics
        let fetchDescriptor = FetchDescriptor<Station>()
        if let allStations = try? modelContext.fetch(fetchDescriptor) {
            FuelPriceIngestor.calculateAnalytics(for: allStations)
        }
        
        try? modelContext.save()
    }
}
