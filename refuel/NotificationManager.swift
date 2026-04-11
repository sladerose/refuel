import Foundation
import UserNotifications
import OSLog

@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private let logger = Logger(subsystem: "com.slade.refuel", category: "NotificationManager")
    private let center = UNUserNotificationCenter.current()
    
    var isAuthorized = false
    var pendingStationID: UUID? // For deep linking
    
    override init() {
        super.init()
        center.delegate = self
        checkAuthorization()
    }
    
    func requestPermissions() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                self.logger.error("Error requesting notification permissions: \(error.localizedDescription)")
            }
            self.isAuthorized = granted
        }
    }
    
    func checkAuthorization() {
        center.getNotificationSettings { settings in
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    func scheduleLocalNotification(title: String, body: String, identifier: String, stationID: UUID? = nil, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let stationID = stationID {
            content.userInfo = ["stationID": stationID.uuidString]
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                self.logger.error("Error scheduling notification \(identifier): \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let stationIDString = userInfo["stationID"] as? String, let uuid = UUID(uuidString: stationIDString) {
            self.pendingStationID = uuid
        }
        completionHandler()
    }
}
