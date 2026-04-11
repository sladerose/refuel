import Testing
import CoreLocation
import Foundation
@testable import refuel

@MainActor
struct GeofenceTests {
    @Test func testGeofenceServiceInitialization() async throws {
        let service = GeofenceService()
        #expect(service != nil)
    }

    @Test func testGeofenceServiceMonitoring() async throws {
        let service = GeofenceService()
        let center = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093) // Sydney
        let radius: CLLocationDistance = 5000.0 // 5km
        
        await service.monitorRegion(center: center, radius: radius, identifier: "current_search")
        
        let isMonitoring = await service.isMonitoring(identifier: "current_search")
        #expect(isMonitoring == true)
        
        // Note: We can't easily trigger a real geofence event in a unit test 
        // without complex mocking of CLMonitor, but we can verify monitoring is active.
    }
}
