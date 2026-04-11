//
//  SearchService.swift
//  refuel
//

import Foundation
import MapKit
import Observation

@Observable
final class SearchService {
    var searchResults: [MKMapItem] = []
    var isSearching = false
    
    func search(query: String, region: MKCoordinateRegion?) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let region = region {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            defer { self?.isSearching = false }
            
            if let response = response {
                self?.searchResults = response.mapItems
            } else if let error = error {
                print("Search error: \(error.localizedDescription)")
                self?.searchResults = []
            }
        }
    }
}
