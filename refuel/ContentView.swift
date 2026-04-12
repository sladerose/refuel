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
    @Query private var stations: [Station]
    
    @State private var viewModel: ContentViewModel
    @State private var selectedTab = 0
    @State private var selectedStation: Station?
    
    init(modelContainer: ModelContainer) {
        let vm = ContentViewModel(modelContainer: modelContainer)
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        Group {
            if viewModel.locationManager.isAuthorized {
                VStack(spacing: 0) {
                    if viewModel.proactiveService.isHikeImminent {
                        HikeAlertBanner(proactiveService: viewModel.proactiveService)
                    }
                    
                    TabView(selection: $selectedTab) {
                        MapView()
                            .environment(viewModel.locationManager)
                            .environment(viewModel.searchService)
                            .tabItem {
                                Label("Map", systemImage: "map")
                            }
                            .tag(0)
                        
                        StationListView(filterFavorites: false, onRefresh: refreshPrices)
                            .environment(viewModel.locationManager)
                            .tabItem {
                                Label("List", systemImage: "list.bullet")
                            }
                            .tag(1)
                        
                        StationListView(filterFavorites: true, onRefresh: refreshPrices)
                            .environment(viewModel.locationManager)
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
                .environment(viewModel.gamificationManager)
                .environment(viewModel.proactiveService)
                .onAppear {
                    viewModel.notificationManager.requestPermissions()
                }
                .onChange(of: viewModel.notificationManager.pendingStationID) { _, newValue in
                    if let uuid = newValue {
                        selectedStation = stations.first(where: { $0.id == uuid })
                        selectedTab = 0
                        viewModel.notificationManager.pendingStationID = nil
                    }
                }
                .sheet(item: $selectedStation, content: stationDetailSheet)
                .overlay {
                    if viewModel.isRefreshing {
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
                    if viewModel.shouldRefresh(stations: stations) {
                        await refreshPrices()
                    }
                }
                .task {
                    // Start listening for geofence exit events
                    for await _ in viewModel.geofenceService.exitEvents {
                        await refreshPrices()
                    }
                }
                .onChange(of: viewModel.locationManager.userLocation) { _, _ in
                    Task {
                        if viewModel.shouldRefresh(stations: stations) {
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
                        viewModel.locationManager.requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    @ViewBuilder
    private func stationDetailSheet(station: Station) -> some View {
        NavigationStack {
            StationDetailView(station: station)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { selectedStation = nil }
                    }
                }
        }
    }
    
    private func refreshPrices() async {
        await viewModel.refreshPrices(modelContext: modelContext, stations: stations)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([Station.self, FuelPrice.self, RefuelEvent.self, UserProfile.self, LuckyDrawEntry.self]), configurations: [config])
    return ContentView(modelContainer: container)
        .modelContainer(container)
}
