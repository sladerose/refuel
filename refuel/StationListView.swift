import SwiftUI
import SwiftData
import CoreLocation

struct StationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) var locationManager
    
    @Query var stations: [Station]
    
    let filterFavorites: Bool
    let onRefresh: (() async -> Void)?
    @State private var sortOption: SortOption = .distance
    
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
    }
    
    var sortedStations: [Station] {
        switch sortOption {
        case .distance:
            return stations.sorted {
                let locA = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                let locB = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
                let distA = locationManager.userLocation?.distance(from: locA) ?? .infinity
                let distB = locationManager.userLocation?.distance(from: locB) ?? .infinity
                return distA < distB
            }
        case .price:
            return stations.sorted {
                let minPriceA = $0.prices.map(\.price).min() ?? .infinity
                let minPriceB = $1.prices.map(\.price).min() ?? .infinity
                return minPriceA < minPriceB
            }
        }
    }
    
    var averageMinPrice: Double? {
        let minPrices = stations.compactMap { $0.prices.map(\.price).min() }
        guard !minPrices.isEmpty else { return nil }
        return minPrices.reduce(0, +) / Double(minPrices.count)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Sort By", selection: $sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.ultraThinMaterial)
                
                List(sortedStations) { station in
                    NavigationLink {
                        StationDetailView(station: station)
                    } label: {
                        StationRow(station: station, localAverage: averageMinPrice)
                    }
                }
                .refreshable {
                    await onRefresh?()
                }
            }
            .navigationTitle(filterFavorites ? "Favorite Stations" : "Nearby Stations")
            .overlay {
                if stations.isEmpty {
                    ContentUnavailableView("No Stations Found", systemImage: "fuelpump.slash", description: Text("Try searching in a different area."))
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
    
    var valueSummary: String? {
        guard let localAverage = localAverage,
              let minPrice = station.prices.map(\.price).min() else { return nil }
        
        let diff = minPrice - localAverage
        if abs(diff) < 0.005 {
            return "Average price"
        } else if diff < 0 {
            return String(format: "$%.2f cheaper than avg", abs(diff))
        } else {
            return String(format: "$%.2f more than avg", diff)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    station.isFavorite.toggle()
                } label: {
                    Image(systemName: station.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(station.isFavorite ? .red : .gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(station.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                .accessibilityValue(station.isFavorite ? "Favorited" : "Not Favorited")
                
                Text(station.name)
                    .font(.headline)
                Spacer()
                if let summary = valueSummary {
                    Text(summary)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(station.ragStatus.color.opacity(0.2))
                        .foregroundColor(station.ragStatus.color)
                        .clipShape(Capsule())
                }
                Text(distanceString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(station.address)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                ForEach(station.prices.sorted(by: { $0.grade < $1.grade })) { price in
                    VStack {
                        Text(price.grade)
                            .font(.caption2)
                            .fontWeight(.bold)
                        Text(String(format: "$%.2f", price.price))
                            .font(.caption)
                    }
                    .padding(6)
                    .background(station.ragStatus.color.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Station.self, configurations: config)
    
    return StationListView(filterFavorites: false, onRefresh: nil)
        .modelContainer(container)
        .environment(LocationManager())
}
