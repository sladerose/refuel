//
//  NavigationService.swift
//  refuel
//

import Foundation
import CoreLocation
import UIKit

enum NavigationApp: String, CaseIterable, Identifiable {
    case appleMaps = "Apple Maps"
    case googleMaps = "Google Maps"
    
    var id: String { self.rawValue }
    
    var urlScheme: String {
        switch self {
        case .appleMaps: return "maps://"
        case .googleMaps: return "comgooglemaps://"
        }
    }
}

final class NavigationService {
    static let shared = NavigationService()
    
    private init() {}
    
    func canOpen(app: NavigationApp) -> Bool {
        guard let url = URL(string: app.urlScheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func open(app: NavigationApp, coordinate: CLLocationCoordinate2D, label: String = "Station") {
        let name = label.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "Station"
        let urlString: String
        
        switch app {
        case .appleMaps:
            // Apple Maps supports label via the q parameter or appending to daddr
            urlString = "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)&q=\(name)&t=m"
        case .googleMaps:
            // Google Maps uses daddr for destination; label is often inferred or can be part of search
            urlString = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"
            // Note: Google Maps URL scheme is limited for combined coord+label navigation
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
