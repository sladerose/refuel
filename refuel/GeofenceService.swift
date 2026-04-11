import CoreLocation
import Foundation
import OSLog

@Observable
final class GeofenceService: NSObject, CLLocationManagerDelegate {
    private let logger = Logger(subsystem: "com.slade.refuel", category: "GeofenceService")
    private let manager = CLLocationManager()
    
    private var continuation: AsyncStream<CLLocationCoordinate2D>.Continuation?
    private var regionContinuation: AsyncStream<(CLRegion, Bool)>.Continuation?
    let exitEvents: AsyncStream<CLLocationCoordinate2D>
    let regionEvents: AsyncStream<(CLRegion, Bool)>

    override init() {
        var capturedContinuation: AsyncStream<CLLocationCoordinate2D>.Continuation?
        self.exitEvents = AsyncStream { capturedContinuation = $0 }
        self.continuation = capturedContinuation
        
        var capturedRegionContinuation: AsyncStream<(CLRegion, Bool)>.Continuation?
        self.regionEvents = AsyncStream { capturedRegionContinuation = $0 }
        self.regionContinuation = capturedRegionContinuation
        
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func monitorStation(id: UUID, latitude: Double, longitude: Double) {
        let identifier = "station_\(id.uuidString)"
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: 100, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        manager.startMonitoring(for: region)
    }
    
    func monitorRegion(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        // Stop monitoring existing regions with same identifier
        for region in manager.monitoredRegions {
            if region.identifier == identifier {
                manager.stopMonitoring(for: region)
            }
        }
        
        logger.info("Monitoring region at \(center.latitude), \(center.longitude) with radius \(radius)m")
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnExit = true
        region.notifyOnEntry = false
        
        manager.startMonitoring(for: region)
    }
    
    func isMonitoring(identifier: String) -> Bool {
        manager.monitoredRegions.contains { $0.identifier == identifier }
    }

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        logger.info("Entered region: \(region.identifier)")
        regionContinuation?.yield((region, true))
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == "current_search" {
            guard let circularRegion = region as? CLCircularRegion else { return }
            logger.info("Geofence exit detected for search area")
            continuation?.yield(circularRegion.center)
        } else {
            logger.info("Exited region: \(region.identifier)")
            regionContinuation?.yield((region, false))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        logger.error("Monitoring failed for region \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }
}
