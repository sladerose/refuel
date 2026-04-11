# Architecture Patterns

**Domain:** iOS Fuel Tracker (SwiftUI / MapKit / SwiftData)
**Researched:** 2024-05-24
**Confidence:** HIGH

## Recommended Architecture

The recommended architecture is a **Layered Service-Oriented Architecture** utilizing modern Swift Concurrency (Async/Await) and SwiftData. This decouples the UI from persistence and external data sources, ensuring testability and background performance.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **View Layer** | Renders UI (Map, List, Station Details). Handles user gestures. | ViewModels, SwiftUI Environment |
| **ViewModel Layer** | Manages UI state, coordinates between services, and transforms data for display (e.g., RAG logic). | Services, Domain Entities |
| **Service Layer** | Business logic (Location tracking, Price fetching, Route calculation). | Repositories, API Clients |
| **Repository Layer** | Abstraction for Data Storage. Handles mapping between SwiftData and Domain Entities. | SwiftData (ModelContext), Services |
| **Domain Layer** | Pure Swift structs representing core business concepts (Station, FuelPrice, PriceStatus). | All layers (Shared) |

### Data Flow

1. **Trigger:** `LocationService` detects movement (Foreground) or `BGTaskScheduler` fires (Background).
2. **Fetch:** `FuelPriceService` makes an async call to the External API for the current geofence.
3. **Persist:** `StationRepository` receives DTOs, updates `FuelStationSD` (SwiftData) via a `ModelActor` to keep the main thread free.
4. **Notify:** SwiftData triggers a reactive update or the ViewModel refreshes its `Observable` state.
5. **Display:** `MapView` and `ListView` render the updated `FuelStation` domain entities.

---

## Patterns to Follow

### Pattern 1: Repository with ModelActor
SwiftData operations should be offloaded to a `ModelActor` to prevent blocking the UI during large updates or complex queries.

**Example:**
```swift
@ModelActor
actor StationRepository {
    func updateStations(with dtos: [StationDTO]) throws {
        for dto in dtos {
            let fetchDescriptor = FetchDescriptor<FuelStationSD>(
                predicate: #Predicate { $0.remoteId == dto.id }
            )
            if let existing = try modelContext.fetch(fetchDescriptor).first {
                existing.update(from: dto)
            } else {
                modelContext.insert(FuelStationSD(from: dto))
            }
        }
        try modelContext.save()
    }
}
```

### Pattern 2: Domain Entity Mapping
Never pass `SwiftData` objects directly to the View if they need to be manipulated or if you want to avoid "Live Object" crashes/complexity. Map them to plain `structs`.

**Example:**
```swift
struct FuelStation: Identifiable, Equatable {
    let id: UUID
    let name: String
    let price: Double
    let status: PriceStatus // Calculated by Service/ViewModel
}
```

### Pattern 3: Modern Map Interaction (iOS 17+)
Use `MapCameraPosition` and `selection` binding for idiomatic SwiftUI map control.

**Example:**
```swift
Map(position: $position, selection: $selectedStationID) {
    ForEach(stations) { station in
        Marker(station.name, coordinate: station.coordinate)
            .tag(station.id)
            .tint(station.status.color)
    }
}
.mapControls {
    MapUserLocationButton()
    MapCompass()
}
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Heavy View Logic
**What:** Performing RAG (Red-Amber-Green) calculations or distance sorting inside the `body` of a SwiftUI View.
**Why bad:** Causes stuttering during map pans as the View body re-evaluates frequently.
**Instead:** Perform these calculations in the ViewModel or a Background Service and provide a "ready-to-render" list.

### Anti-Pattern 2: Global Singleton Location Manager
**What:** Using a single shared `CLLocationManager` throughout the app without proper lifecycle management.
**Why bad:** Leads to unexpected battery drain and hard-to-test location logic.
**Instead:** Wrap location logic in a `LocationService` that uses `CLBackgroundActivitySession` and `CLLocationUpdate.liveUpdates`.

---

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| **Map Rendering** | Simple `ForEach` with `Marker` | `Marker` still fine for local radius | Consider `MKMapView` with clustering |
| **Data Fetching** | Direct API calls | API Caching / CDN | Edge-cached prices per geohash |
| **Storage** | SwiftData local store | SwiftData + CloudKit sync | Advanced local pruning of old data |

---

## Sources

- [Apple Documentation: MapKit for SwiftUI](https://developer.apple.com/documentation/mapkit/map) (HIGH)
- [SwiftData ModelActor Documentation](https://developer.apple.com/documentation/swiftdata/modelactor) (HIGH)
- [Core Location: liveUpdates API](https://developer.apple.com/documentation/corelocation/cllocationupdate) (HIGH)
- [Point-Free: Modern SwiftUI Architecture](https://www.pointfree.co/) (MEDIUM)
