//
//  ContentView.swift
//  refuel
//
//  Created by slade on 2026/04/11.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var searchService = SearchService()

    var body: some View {
        Group {
            if locationManager.isAuthorized {
                MapView()
                    .environment(locationManager)
                    .environment(searchService)
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
}

#Preview {
    ContentView()
        .modelContainer(for: [Station.self, FuelPrice.self], inMemory: true)
}
