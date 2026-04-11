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
    @State private var gamificationManager: GamificationManager
    @State private var notificationManager = NotificationManager()
    @State private var proactiveService: ProactiveService
    
    @Query private var stations: [Station]
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var selectedStationID: UUID?
    
    init(modelContainer: ModelContainer) {
        let gManager = GamificationManager(modelContainer: modelContainer)
        _gamificationManager = State(initialValue: gManager)
        
        let gService = GeofenceService()
        _geofenceService = State(initialValue: gService)
        
        let nManager = NotificationManager()
        _notificationManager = State(initialValue: nManager)
        
        _proactiveService = State(initialValue: ProactiveService(geofenceService: gService, notificationManager: nManager, modelContainer: modelContainer))
    }

    var body: some View {
        Group {
            if locationManager.isAuthorized {
                VStack(spacing: 0) {
                    if proactiveService.isHikeImminent {
                        HikeAlertBanner(proactiveService: proactiveService)
                    }
                    
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
                        
                        ProfileView()
                            .tabItem {
                                Label("Profile", systemImage: "person.circle.fill")
                            }
                            .tag(4)
                    }
                }
                .environment(gamificationManager)
                .environment(proactiveService)
                .onAppear {
                    notificationManager.requestPermissions()
                }
                .onChange(of: notificationManager.pendingStationID) { _, newValue in
                    if let uuid = newValue {
                        selectedStationID = uuid
                        selectedTab = 0
                        notificationManager.pendingStationID = nil
                    }
                }
                .sheet(item: $selectedStationID) { uuid in
                    if let station = stations.first(where: { $0.id == uuid }) {
                        NavigationStack {
                            StationDetailView(station: station)
                                .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button("Done") { selectedStationID = nil }
                                    }
                                }
                        }
                    }
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
            
            // Start monitoring nearby stations for dwell detection
            for station in stations {
                geofenceService.monitorStation(id: station.id, latitude: station.latitude, longitude: station.longitude)
            }
        } catch {
            print("Failed to refresh prices: \(error)")
        }
    }
}

struct HikeAlertBanner: View {
    let proactiveService: ProactiveService
    
    var body: some View {
        HStack {
            Image(systemName: "fuelpump.fill")
                .foregroundColor(.white)
            VStack(alignment: .leading) {
                Text("Fuel Hike Imminent!")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("Prices rise in \(timeRemaining)")
                    .font(.caption)
            }
            .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.red)
    }
    
    var timeRemaining: String {
        let diff = proactiveService.nextFirstWednesday().timeIntervalSinceNow
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

extension UUID: Identifiable {
    public var id: String { self.uuidString }
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
                    HStack {
                        Button {
                            showingScanner = true
                        } label: {
                            Image(systemName: "camera")
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
            if let existingPrice = station.prices.first(where: { $0.grade == grade }) {
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([Station.self, FuelPrice.self, RefuelEvent.self, UserProfile.self]), configurations: [config])
    return ContentView(modelContainer: container)
        .modelContainer(container)
}
