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
        
        var entries = [PriceEntry]()
        for (grade, price) in detectedPrices {
            entries.append(PriceEntry(grade: grade, price: price))
        }
        
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
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(station.name)
                            .font(.headline)
                        Text("Please confirm or correct the scanned prices below.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    if editedPrices.isEmpty {
                        ContentUnavailableView("No Prices Found", systemImage: "text.magnifyingglass", description: Text("Scanning didn't find any prices. Use the button below to add them manually."))
                    } else {
                        ForEach($editedPrices) { $entry in
                            HStack {
                                Label {
                                    Text(entry.grade)
                                        .fontWeight(.semibold)
                                } icon: {
                                    Image(systemName: "fuelpump.fill")
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                TextField("Price", value: $entry.price, format: .currency(code: "ZAR"))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .fontWeight(.bold)
                                    .frame(width: 120)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .onDelete { indexSet in
                            editedPrices.remove(atOffsets: indexSet)
                        }
                    }
                } header: {
                    Text("Detected Prices")
                }
                
                Section {
                    Button(action: {
                        editedPrices.append(PriceEntry(grade: "95", price: 0.0))
                    }) {
                        Label("Add Another Grade", systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.blue)
                }
            }
            .listStyle(.insetGrouped)
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
                    .fontWeight(.bold)
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
