//
//  HistoryViews.swift
//  refuel
//
//  Created by slade on 2026/04/12.
//

import SwiftUI
import SwiftData

struct RefuelHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RefuelEvent.date, order: .reverse) private var logs: [RefuelEvent]
    @Query private var stations: [Station]
    
    let onRefresh: (() async -> Void)?
    
    init(onRefresh: (() async -> Void)? = nil) {
        self.onRefresh = onRefresh
    }
    
    @State private var showingAddLog = false
    @State private var showingScanner = false
    @State private var scannedData: ScannedReceiptData?
    
    var totalSpend: Double {
        logs.reduce(0) { $0 + $1.totalCost }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Spent")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text(String(format: "R%.2f", totalSpend))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Records")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("\(logs.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Recent Activity") {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(log.stationName)
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "R%.2f", log.totalCost))
                                    .font(.subheadline.bold().monospaced())
                            }
                            
                            HStack {
                                Label(log.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                Spacer()
                                Text("\(String(format: "%.1f", log.amountInLitres))L @ R\(String(format: "%.2f", log.pricePerLitre))/L")
                                    .monospaced()
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Text(log.grade)
                                .font(.caption2.weight(.black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteLogs)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await onRefresh?()
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            showingScanner = true
                        } label: {
                            Image(systemName: "camera.viewfinder")
                        }
                        
                        Button {
                            scannedData = nil
                            showingAddLog = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ReceiptScannerView { result in
                    switch result {
                    case .success(let images):
                        OCRService.shared.process(images: images, stations: stations) { data in
                            self.scannedData = data
                            self.showingAddLog = true
                        }
                    case .failure(let error):
                        print("Scanner failed: \(error)")
                    }
                }
            }
            .sheet(isPresented: $showingAddLog) {
                AddRefuelLogView(stations: stations, initialData: scannedData)
            }
            .overlay {
                if logs.isEmpty {
                    ContentUnavailableView("No Logs Yet", systemImage: "fuelpump", description: Text("Start tracking your fuel costs by adding your first refuel event."))
                }
            }
        }
    }
    
    private func deleteLogs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(logs[index])
            }
        }
    }
}

struct AddRefuelLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(GamificationManager.self) private var gamificationManager
    
    let stations: [Station]
    let initialData: ScannedReceiptData?
    
    @State private var date: Date
    @State private var amount: String
    @State private var price: String
    @State private var grade: String
    @State private var selectedStation: Station?
    @State private var customStationName: String
    
    init(stations: [Station], initialData: ScannedReceiptData? = nil) {
        self.stations = stations
        self.initialData = initialData
        
        _date = State(initialValue: initialData?.date ?? Date())
        _amount = State(initialValue: initialData?.amountInLitres != nil ? String(format: "%.2f", initialData!.amountInLitres!) : "")
        _price = State(initialValue: initialData?.pricePerLitre != nil ? String(format: "%.2f", initialData!.pricePerLitre!) : "")
        _grade = State(initialValue: initialData?.grade ?? "91")
        
        let matchedStation = stations.first(where: { $0.name == initialData?.stationName })
        _selectedStation = State(initialValue: matchedStation)
        _customStationName = State(initialValue: (matchedStation == nil) ? (initialData?.stationName ?? "") : "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Amount (Litres)", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Price per Litre", text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField("Fuel Grade", text: $grade)
                }
                
                Section("Station") {
                    Picker("Select Station", selection: $selectedStation) {
                        Text("None / Other").tag(nil as Station?)
                        ForEach(stations) { station in
                            Text(station.name).tag(station as Station?)
                        }
                    }
                    
                    if selectedStation == nil {
                        TextField("Station Name", text: $customStationName)
                    }
                }
            }
            .navigationTitle("Log Refuel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLog()
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    var isValid: Bool {
        guard Double(amount) != nil, Double(price) != nil else { return false }
        if selectedStation == nil && customStationName.isEmpty { return false }
        return true
    }
    
    private func saveLog() {
        guard let amountVal = Double(amount), let priceVal = Double(price) else { return }
        
        let name = selectedStation?.name ?? customStationName
        let log = RefuelEvent(
            date: date,
            amountInLitres: amountVal,
            pricePerLitre: priceVal,
            grade: grade,
            stationName: name,
            station: selectedStation
        )
        modelContext.insert(log)
        
        // Award XP
        if initialData != nil {
            // Scanned receipt
            gamificationManager.awardXP(amount: 50, stationName: name, type: "scan")
        } else {
            // Manual entry
            gamificationManager.awardXP(amount: 10, stationName: name, type: "manual")
        }
        
        // Update the station's price if we have a linked station
        // Only update if the refuel is recent (last 24 hours)
        if let station = selectedStation, abs(date.timeIntervalSinceNow) < 86400 {
            if let existingPrice = (station.prices ?? []).first(where: { $0.grade == grade }) {
                existingPrice.price = priceVal
                existingPrice.timestamp = date
            } else {
                let newPrice = FuelPrice(grade: grade, price: priceVal, timestamp: date, station: station)
                modelContext.insert(newPrice)
            }
            
            // Re-run analytics since we updated a price
            let fetchDescriptor = FetchDescriptor<Station>()
            if let allStations = try? modelContext.fetch(fetchDescriptor) {
                FuelPriceIngestor.calculateAnalytics(for: allStations)
            }
        }
    }
}
