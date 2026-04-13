import Testing
import CoreLocation
import Foundation
@testable import refuel

@MainActor
struct GeofenceTests {
    @Test func testGeofenceServiceInitialization() async throws {
        let _ = GeofenceService()
        #expect(true) // If we reach here, init worked
    }

    @Test func testGeofenceServiceMonitoring() async throws {
        let service = GeofenceService()
        let center = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093) // Sydney
        let radius: CLLocationDistance = 5000.0 // 5km
        
        service.monitorRegion(center: center, radius: radius, identifier: "current_search")
        
        // Give the system a moment to register the monitoring request
        try await Task.sleep(for: .milliseconds(100))
        
        let isMonitoring = service.isMonitoring(identifier: "current_search")
        #expect(isMonitoring == true)
    }
}
