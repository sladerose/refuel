//
//  LocationManager.swift
//  refuel
//

import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    var userLocation: CLLocation?
    var isAuthorized = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        checkAuthorization()
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    private func checkAuthorization() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            startLocationUpdates()
        case .notDetermined:
            isAuthorized = false
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    func startLocationUpdates() {
        Task {
            do {
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    if let location = update.location {
                        self.userLocation = location
                    }
                    
                    // Break if no longer authorized (safety check)
                    if !isAuthorized { break }
                }
            } catch {
                print("Error receiving location updates: \(error)")
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
}
