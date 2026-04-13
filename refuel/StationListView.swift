import SwiftUI
import SwiftData
import CoreLocation

struct StationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) var locationManager
    @Environment(GamificationManager.self) private var gamificationManager
    
    @Query var stations: [Station]
    
    let filterFavorites: Bool
    let onRefresh: (() async -> Void)?
    @State private var sortOption: SortOption = .distance
    
    @State private var showingBoardScanner = false
    @State private var showingVerification = false
    @State private var selectedStationForScan: Station?
    @State private var detectedBoardPrices: [String: Double] = [:]
    
    init(filterFavorites: Bool = false, onRefresh: (() async -> Void)? = nil) {
        self.filterFavorites = filterFavorites
        self.onRefresh = onRefresh
        
        if filterFavorites {
            _stations = Query(filter: #Predicate<Station> { $0.isFavorite }, sort: \Station.name)
        }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case distance = "Distance"
        case price = "Price"
        var id: String { self.rawValue }
        
        var systemImage: String {
            switch self {
            case .distance: return "location.fill"
            case .price: return "dollarsign.circle.fill"
            }
        }
    }
    
    var sortedStations: [Station] {
        switch sortOption {
        case .distance:
            return stations.sorted(by: { a, b in
                let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
                let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
                let distA = locationManager.userLocation?.distance(from: locA) ?? .infinity
                let distB = locationManager.userLocation?.distance(from: locB) ?? .infinity
                return distA < distB
            })
        case .price:
            return stations.sorted(by: { a, b in
                let minPriceA = (a.prices ?? []).compactMap { $0.price }.min() ?? .infinity
                let minPriceB = (b.prices ?? []).compactMap { $0.price }.min() ?? .infinity
                return minPriceA < minPriceB
            })
        }
    }
    
    var averageMinPrice: Double? {
        let minPrices = stations.compactMap { ( $0.prices ?? [] ).compactMap { $0.price }.min() }
        guard !minPrices.isEmpty else { return nil }
        return minPrices.reduce(0, +) / Double(minPrices.count)
    }
    
    var body: some View {
        NavigationStack {
            List(sortedStations) { station in
                NavigationLink {
                    StationDetailView(station: station)
                } label: {
                    StationRow(station: station, localAverage: averageMinPrice)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        selectedStationForScan = station
                        showingBoardScanner = true
                    } label: {
                        Label("Scan Board", systemImage: "camera.viewfinder")
                    }
                    .tint(.orange)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await onRefresh?()
            }
            .navigationTitle(filterFavorites ? "Favorites" : "Nearby Stations")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    StreakIndicator()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Label(option.rawValue, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingBoardScanner) {
                PriceBoardScannerContainer { results in
                    self.detectedBoardPrices = results
                    self.showingVerification = true
                    if let station = selectedStationForScan {
                        gamificationManager.awardXP(amount: 30, stationName: station.name, type: "board_scan")
                    }
                }
            }
            .sheet(isPresented: $showingVerification) {
                if let station = selectedStationForScan {
                    PriceVerificationView(station: station, detectedPrices: detectedBoardPrices)
                }
            }
            .overlay {
                if stations.isEmpty {
                    ContentUnavailableView {
                        Label(filterFavorites ? "No Favorites" : "No Stations Found", 
                              systemImage: filterFavorites ? "heart.slash" : "fuelpump.slash")
                    } description: {
                        Text(filterFavorites ? "Stations you heart will appear here." : "Try searching in a different area.")
                    } actions: {
                        if filterFavorites {
                            NavigationLink {
                                StationListView(filterFavorites: false, onRefresh: onRefresh)
                            } label: {
                                Text("Explore Nearby")
                                    .fontWeight(.bold)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                }
            }
        }
    }
}

struct StationRow: View {
    let station: Station
    let localAverage: Double?
    @Environment(LocationManager.self) var locationManager

    var distanceString: String {
        guard let userLocation = locationManager.userLocation else { return "Calculating..." }
        let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
        let distance = userLocation.distance(from: stationLocation)
        return String(format: "%.1f km", distance / 1000)
    }

    var valueSummary: (text: String, color: Color)? {
        guard let localAverage,
              let minPrice = (station.prices ?? []).map(\.price).min() else { return nil }
        let diff = minPrice - localAverage
        if abs(diff) < 0.005 {
            return ("Avg", .secondary)
        } else if diff < 0 {
            return (String(format: "-R%.2f", abs(diff)), station.ragStatus.color)
        } else {
            return (String(format: "+R%.2f", diff), station.ragStatus.color)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Station name + distance
            HStack(alignment: .firstTextBaseline) {
                Text(station.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(distanceString)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            // Address
            Text(station.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Fuel grade chips
            HStack(alignment: .center, spacing: 6) {
                ForEach((station.prices ?? []).sorted(by: { $0.grade < $1.grade })) { price in
                    HStack(spacing: 4) {
                        Text(price.grade)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text(String(format: "R%.2f", price.price))
                            .font(.caption.weight(.bold).monospaced())
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // RAG badge
            if let summary = valueSummary {
                Text(summary.text)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(summary.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(summary.color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Station.self, configurations: config)
    
    return StationListView(filterFavorites: false, onRefresh: nil)
        .modelContainer(container)
        .environment(LocationManager())
}
