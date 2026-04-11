import Foundation
import CoreLocation
import SwiftData
import Observation
import OSLog

@Observable
final class ProactiveService {
    private let logger = Logger(subsystem: "com.slade.refuel", category: "ProactiveService")
    private let geofenceService: GeofenceService
    private let notificationManager: NotificationManager
    private let modelContext: ModelContext
    
    private var dwellTimers: [String: Timer] = [:]
    private var lastContributionDate: Date?
    
    init(geofenceService: GeofenceService, notificationManager: NotificationManager, modelContainer: ModelContainer) {
        self.geofenceService = geofenceService
        self.notificationManager = notificationManager
        self.modelContext = ModelContext(modelContainer)
        
        startListening()
        scheduleHikeAlerts()
    }
    
    private func startListening() {
        Task {
            for await (region, isEntry) in geofenceService.regionEvents {
                if isEntry {
                    handleEntry(region: region)
                } else {
                    handleExit(region: region)
                }
            }
        }
    }
    
    private func handleEntry(region: CLRegion) {
        guard region.identifier.hasPrefix("station_") else { return }
        let stationIDString = region.identifier.replacingOccurrences(of: "station_", with: "")
        
        // Start a 2-minute timer for dwell detection
        let timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self] _ in
            self?.triggerDwellNotification(stationIDString: stationIDString)
        }
        dwellTimers[region.identifier] = timer
    }
    
    private func handleExit(region: CLRegion) {
        dwellTimers[region.identifier]?.invalidate()
        dwellTimers.removeValue(forKey: region.identifier)
        
        guard region.identifier.hasPrefix("station_") else { return }
        let stationIDString = region.identifier.replacingOccurrences(of: "station_", with: "")
        
        // Schedule "Forget to scan?" notification after 10 mins if no contribution
        // We'll check for a contribution in the last 15 minutes
        let fifteenMinsAgo = Date().addingTimeInterval(-900)
        let fetchDescriptor = FetchDescriptor<RefuelEvent>(
            predicate: #Predicate { $0.date > fifteenMinsAgo }
        )
        
        let recentLogs = (try? modelContext.fetch(fetchDescriptor)) ?? []
        
        if recentLogs.isEmpty {
            notificationManager.scheduleLocalNotification(
                title: "Forget to scan?",
                body: "We saw you visited a station recently. Scan your receipt to earn XP!",
                identifier: "followup_\(stationIDString)",
                stationID: UUID(uuidString: stationIDString),
                timeInterval: 600 // 10 minutes
            )
        }
    }
    
    private func triggerDwellNotification(stationIDString: String) {
        guard let uuid = UUID(uuidString: stationIDString) else { return }
        
        // Fetch station name for better notification
        let fetchDescriptor = FetchDescriptor<Station>(predicate: #Predicate { $0.id == uuid })
        let station = (try? modelContext.fetch(fetchDescriptor))?.first
        let name = station?.name ?? "the station"
        
        notificationManager.scheduleLocalNotification(
            title: "Still correct?",
            body: "Are the prices at \(name) still up to date? Tap to verify and earn XP!",
            identifier: "dwell_\(stationIDString)",
            stationID: uuid
        )
    }
    
    // MARK: - Hike Alerts
    
    private func scheduleHikeAlerts() {
        let nextWednesday = nextFirstWednesday()
        let alertDate = nextWednesday.addingTimeInterval(-86400) // 24 hours before
        
        let interval = alertDate.timeIntervalSinceNow
        if interval > 0 {
            notificationManager.scheduleLocalNotification(
                title: "Fuel Hike Alert!",
                body: "Prices are expected to rise tomorrow. Fill up today to save!",
                identifier: "hike_alert",
                timeInterval: interval
            )
        }
    }
    
    func nextFirstWednesday() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.day = 1
        
        // Get the first day of current month
        guard var date = calendar.date(from: components) else { return Date() }
        
        // Find first Wednesday
        while calendar.component(.weekday, from: date) != 4 { // 4 = Wednesday
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        // If it's already passed this month, get next month
        if date < Date() {
            components.month! += 1
            date = calendar.date(from: components)!
            while calendar.component(.weekday, from: date) != 4 {
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
        }
        
        return date
    }
    
    var isHikeImminent: Bool {
        let nextWed = nextFirstWednesday()
        let diff = nextWed.timeIntervalSinceNow
        return diff > 0 && diff < 172800 // 48 hours
    }
}
