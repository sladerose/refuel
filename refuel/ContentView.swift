//
//  ContentView.swift
//  refuel
//
//  Created by slade on 2026/04/11.
//

import SwiftUI
import SwiftData
import CoreLocation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var locationManager = LocationManager()
    @State private var searchService = SearchService()
    @State private var geofenceService = GeofenceService()
    
    @Query private var stations: [Station]
    @State private var selectedTab = 0
    @State private var isRefreshing = false

    var body: some View {
        Group {
            if locationManager.isAuthorized {
                TabView(selection: $selectedTab) {
                    MapView()
                        .environment(locationManager)
                        .environment(searchService)
                        .tabItem {
                            Label("Map", systemImage: "map")
                        }
                        .tag(0)
                    
                    StationListView(filterFavorites: false, onRefresh: refreshPrices)
                        .environment(locationManager)
                        .tabItem {
                            Label("List", systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    StationListView(filterFavorites: true, onRefresh: refreshPrices)
                        .environment(locationManager)
                        .tabItem {
                            Label("Favorites", systemImage: "heart.fill")
                        }
                        .tag(2)
                    
                    RefuelHistoryView(onRefresh: refreshPrices)
                        .tabItem {
                            Label("History", systemImage: "clock.fill")
                        }
                        .tag(3)
                }
                .overlay {
                    if isRefreshing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Updating Prices...")
                                .font(.headline)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                }
                .task {
                    if shouldRefresh {
                        await refreshPrices()
                    }
                }
                .task {
                    // Start listening for geofence exit events
                    for await _ in geofenceService.exitEvents {
                        await refreshPrices()
                    }
                }
                .onChange(of: locationManager.userLocation) { _, _ in
                    Task {
                        if shouldRefresh {
                            await refreshPrices()
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "location.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("Location Access Required")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("We need your location to show nearby fuel stations and provide the best prices.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Grant Permission") {
                        locationManager.requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private var shouldRefresh: Bool {
        stations.isEmpty || stations.contains(where: { $0.isStale })
    }
    
    private func refreshPrices() async {
        guard let location = locationManager.userLocation, !isRefreshing else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        let ingestor = FuelPriceIngestor(modelContainer: modelContext.container)
        let service = MockFuelPriceService()
        
        do {
            try await ingestor.updatePrices(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                service: service
            )
            
            // Re-establish geofence at new location
            geofenceService.monitorRegion(
                center: location.coordinate,
                radius: 5000, // 5km
                identifier: "current_search"
            )
        } catch {
            print("Failed to refresh prices: \(error)")
        }
    }
}

// MARK: - History Views

struct RefuelHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RefuelEvent.date, order: .reverse) private var logs: [RefuelEvent]
    @Query private var stations: [Station]
    
    let onRefresh: (() async -> Void)?
    
    init(onRefresh: (() async -> Void)? = nil) {
        self.onRefresh = onRefresh
    }
    
    @State private var showingAddLog = false
    
    var totalSpend: Double {
        logs.reduce(0) { $0 + $1.totalCost }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Spent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "$%.2f", totalSpend))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Logs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(logs.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                ForEach(logs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.stationName)
                                .font(.headline)
                            Spacer()
                            Text(String(format: "$%.2f", log.totalCost))
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text(log.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text("\(String(format: "%.2f", log.amountInLitres))L @ \(String(format: "$%.2f", log.pricePerLitre))/L")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Text(log.grade)
                            .font(.caption2)
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
            .refreshable {
                await onRefresh?()
            }
            .navigationTitle("Refuel History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddLog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLog) {
                AddRefuelLogView(stations: stations)
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
    
    let stations: [Station]
    
    @State private var date = Date()
    @State private var amount = ""
    @State private var price = ""
    @State private var grade = "91"
    @State private var selectedStation: Station?
    @State private var customStationName = ""
    
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
            .navigationTitle("Add Refuel")
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Station.self, FuelPrice.self], inMemory: true)
}
