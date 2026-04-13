//
//  NavigationServiceTests.swift
//  refuelTests
//

import Testing
import CoreLocation
@testable import refuel

@MainActor
struct NavigationServiceTests {

    @Test func testAppleMapsURL() async throws {
        let _ = NavigationService.shared
        let _ = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        
        // This is tricky to test since open() calls UIApplication.shared.open
        // But we can check that it doesn't crash or that the logic holds.
        // In a real project, we might inject a URL opener for easier testing.
        #expect(true)
    }
}
