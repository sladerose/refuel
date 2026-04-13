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
    @State private var selectedStation: Station?
    
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            
            ForEach(stations) { station in
                Annotation(station.name, coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)) {
                    MapMarker(station: station) {
                        selectedStation = station
                    }
                }
            }
            
            ForEach(searchService.searchResults, id: \.self) { item in
                Marker(item.name ?? "Search Result", coordinate: item.location.coordinate)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 8) {
                // Native-style Floating Search
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search for a place...", text: $searchText)
                            .submitLabel(.search)
                            .onSubmit {
                                searchService.search(query: searchText, region: nil)
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchService.searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    if !searchService.searchResults.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(searchService.searchResults, id: \.self) { item in
                                    Button {
                                        withAnimation {
                                            let coordinate = item.location.coordinate
                                            position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                                            searchService.searchResults = []
                                            searchText = item.name ?? ""
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name ?? "Unknown")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                            if let address = item.name {
                                                Text(address)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                    }
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxHeight: 250)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                HStack {
                    Spacer()
                    StreakIndicator()
                        .padding(.trailing)
                }
            }
            .padding(.top, 8)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.1), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            )
        }
        .sheet(item: $selectedStation) { station in
            NavigationStack {
                StationDetailView(station: station)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                selectedStation = nil
                            }
                            .fontWeight(.bold)
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct MapMarker: View {
    let station: Station
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                if let cheapestPrice = (station.prices ?? []).min(by: { $0.price < $1.price }) {
                    Text(String(format: "R%.2f", cheapestPrice.price))
                        .font(.caption2.weight(.black).monospaced())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(station.isStale ? Color.gray : station.ragStatus.color, lineWidth: 1)
                        )
                        .offset(y: -2)
                }
                
                ZStack {
                    Circle()
                        .fill(station.isStale ? .gray : station.ragStatus.color)
                        .frame(width: 28, height: 28)
                        .shadow(radius: 2)
                    
                    Image(systemName: "fuelpump.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    if station.isFavorite {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.red)
                            .background(Circle().fill(.white).frame(width: 12, height: 12))
                            .offset(x: 10, y: -10)
                    }
                }
            }
        }
        .buttonStyle(.plain)
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
