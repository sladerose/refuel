//
//  MapView.swift
//  refuel
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(SearchService.self) private var searchService
    @Query private var stations: [Station]
    
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchText = ""
    @State private var isShowingSearch = false
    @State private var selectedStation: Station?
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                UserAnnotation()
                
                // Persisted stations from SwiftData
                ForEach(stations) { station in
                    Annotation(station.name, coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)) {
                        VStack(spacing: 4) {
                            if let cheapestPrice = station.prices.min(by: { $0.price < $1.price }) {
                                Button {
                                    selectedStation = station
                                } label: {
                                    Text(String(format: "$%.2f", cheapestPrice.price))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(station.isStale ? Color.gray : station.ragStatus.color, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Price: \(String(format: "$%.2f", cheapestPrice.price))")
                            }
                            
                            Button {
                                station.isFavorite.toggle()
                            } label: {
                                ZStack {
                                    Image(systemName: "fuelpump.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, station.isStale ? .gray : station.ragStatus.color)
                                        .padding(4)
                                        .background(station.isStale ? .gray : station.ragStatus.color)
                                        .clipShape(Circle())
                                    
                                    if station.isFavorite {
                                        Image(systemName: "heart.fill")
                                            .resizable()
                                            .frame(width: 12, height: 12)
                                            .foregroundColor(.red)
                                            .offset(x: 10, y: -10)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(station.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                            .accessibilityValue(station.isFavorite ? "Favorited" : "Not Favorited")
                        }
                        .accessibilityLabel("\(station.name), \(station.ragStatus.rawValue) value")
                        .accessibilityAction(named: "Toggle Favorite") {
                            station.isFavorite.toggle()
                        }
                        .accessibilityAction(named: "View Details") {
                            selectedStation = station
                        }
                    }
                }
                
                // Future: Search results
                ForEach(searchService.searchResults, id: \.self) { item in
                    Marker(item.name ?? "Search Result", coordinate: item.location.coordinate)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .sheet(item: $selectedStation) { station in
                NavigationStack {
                    StationDetailView(station: station)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    selectedStation = nil
                                }
                            }
                        }
                }
            }
            
            // Search Bar Overlay
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search location...", text: $searchText)
                        .onSubmit {
                            searchService.search(query: searchText, region: nil)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchService.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                
                HStack {
                    Spacer()
                    StreakIndicator()
                        .padding(.trailing)
                }
                
                if !searchService.searchResults.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(searchService.searchResults, id: \.self) { item in
                                Button(action: {
                                    withAnimation {
                                        let coordinate = item.location.coordinate
                                        position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                                    }
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(item.name ?? "Unknown")
                                            .font(.headline)
                                        Text(item.name ?? "")
                                            .font(.caption)
                                    }
                                    .padding()
                                    .background(.thinMaterial)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Station.self, configurations: config)
    
    return MapView()
        .modelContainer(container)
        .environment(LocationManager())
        .environment(SearchService())
}
