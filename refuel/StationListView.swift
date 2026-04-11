import SwiftUI
import SwiftData
import CoreLocation

struct StationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) var locationManager
    
    @Query var stations: [Station]
    
    @State private var sortOption: SortOption = .distance
    
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
    
    var body: some View {
        NavigationStack {
            List(sortedStations) { station in
                StationRow(station: station)
            }
            .navigationTitle("Nearby Stations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
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
    @Environment(LocationManager.self) var locationManager
    
    var distanceString: String {
        guard let userLocation = locationManager.userLocation else { return "Calculating..." }
        let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
        let distance = userLocation.distance(from: stationLocation)
        return String(format: "%.1f km", distance / 1000)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(station.name)
                    .font(.headline)
                Spacer()
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
                    .background(Color.blue.opacity(0.1))
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
    
    return StationListView()
        .modelContainer(container)
        .environment(LocationManager())
}
