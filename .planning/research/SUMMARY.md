# Research Summary: Refuel (iOS Fuel Tracker)

**Status:** Complete
**Date:** 2024-05-24
**Confidence:** HIGH

## Executive Summary

Refuel is a modern iOS fuel tracking application designed to provide users with real-time price transparency and value comparisons. Following expert patterns for iOS 18 development, the product leverages SwiftUI, SwiftData, and MapKit to deliver a high-performance, native experience. The architecture emphasizes a Layered Service-Oriented approach, ensuring that heavy operations—such as price fetching, statistical value analysis (RAG indicators), and local persistence—are decoupled from the UI thread using Swift 6.0 concurrency and `ModelActor`.

The recommended development strategy focuses on delivering "Table Stakes" features (interactive maps and price discovery) alongside a key differentiator: Red-Amber-Green (RAG) indicators that instantly inform users of a station's value relative to its area. To ensure a premium user experience, the project prioritizes performance and battery efficiency by avoiding legacy mapping patterns and strictly managing background location updates.

Key risks include data staleness and map performance stuttering. These are mitigated through a robust caching layer with TTL (Time-To-Live) and the use of modern SwiftUI `Marker` APIs for efficient spatial rendering. By deferring complex secondary features like price alerts and in-app navigation, the MVP can focus on a rock-solid core utility that builds user trust through accuracy and speed.

## Key Findings

### Technology Stack (from STACK.md)
*   **SwiftUI 6.0 (iOS 18):** Primary UI framework for declarative, high-performance rendering.
*   **SwiftData:** Native local persistence with SwiftUI integration for schema management.
*   **MapKit (SwiftUI Native):** Native `Map` views with `Marker` support and `MapCameraPosition`.
*   **Core Location (`liveUpdates`):** iOS 17+ async stream for efficient location tracking.
*   **Swift 6.0 Concurrency:** Mandatory use of Task/Actor model for background safety.

### Feature Landscape (from FEATURES.md)
*   **Must-Haves (Table Stakes):** Interactive Map, Radius Search, Fuel Price Fetching, External Route Navigation.
*   **Differentiators:** RAG Indicators (Price value comparison), Dynamic Geofencing (Background refresh), Offline Cache.
*   **Anti-Features:** In-app turn-by-turn navigation (defer to Apple Maps), User crowdsourcing (use API).

### Architecture Patterns (from ARCHITECTURE.md)
*   **Pattern:** Layered Service-Oriented Architecture.
*   **Persistence:** Use `ModelActor` for SwiftData operations to keep the main thread free.
*   **Decoupling:** Map SwiftData models to pure Domain Entity structs before passing them to the View layer.
*   **State Management:** Built-in `@Observable` macro for lightweight, reactive UI updates.

### Domain Pitfalls (from PITFALLS.md)
*   **Performance:** Avoid custom `Annotation` views for large datasets; use system-optimized `Marker`.
*   **Battery:** Misuse of `CLLocationManager` in background; must use `CLBackgroundActivitySession`.
*   **Data Integrity:** Stale prices; requires mandatory "Last Updated" timestamps and TTL-based refreshing.

## Roadmap Implications

### Suggested Phase Structure

1.  **Phase 1: Core Map & Location Infrastructure**
    *   **Rationale:** Foundational spatial UI and user context.
    *   **Delivers:** Map rendering, user location tracking, and navigation deep-linking.
    *   **Pitfall Avoidance:** Establish battery-efficient location lifecycle early.
2.  **Phase 2: Price Integration & Persistence**
    *   **Rationale:** Establishes the data flow from external API to local cache.
    *   **Delivers:** `FuelPriceService`, `StationRepository` (SwiftData), and list/marker rendering.
    *   **Pitfall Avoidance:** Use `ModelActor` to prevent UI lag during data ingestion.
3.  **Phase 3: Value Analytics (RAG Indicators)**
    *   **Rationale:** Implements the primary unique value proposition (Price status logic).
    *   **Delivers:** Regional price statistical analysis and color-coded map/list UI.
    *   **Pitfall Avoidance:** Perform analytics in Background Service, not in SwiftUI `body`.
4.  **Phase 4: Advanced Backgrounding & Notifications (v2)**
    *   **Rationale:** High complexity background tasks; better suited for iteration after core stability.
    *   **Delivers:** Price drop alerts and geofence-triggered refreshes.

### Research Flags
*   **Needs Research:** Phase 4 (Backgrounding/Alerts) requires a `/gsd-research-phase` for `BGAppRefreshTask` constraints and local notification reliability.
*   **Standard Patterns:** Phases 1-3 follow well-documented SwiftUI/SwiftData patterns and can skip deep research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Based on WWDC23/24 standard modern iOS practices. |
| Features | HIGH | Competitive landscape (GasBuddy/Fuelio) is well-understood. |
| Architecture | HIGH | Service-oriented patterns with Actors are industry standard for Swift 6. |
| Pitfalls | MEDIUM | Real-world battery drain nuances are device-specific; requires testing. |

### Gaps to Address
*   **Data Provider:** Specific external Fuel Price API provider needs to be vetted for cost and reliability during requirements definition.
*   **Clustering:** If the station count exceeds 500+ in a single view, we may need to pivot from SwiftUI `Map` to `MKMapView` for clustering.

## Sources
*   Apple Developer: What's new in SwiftUI (WWDC24)
*   Apple Developer: Meet SwiftData / Meet MapKit for SwiftUI
*   Core Location: liveUpdates API & Best Practices
*   Market Research: GasBuddy / PetrolPrices / Fuelio
*   Point-Free: Modern SwiftUI Architecture
*   StackOverflow: SwiftUI Map performance discussions
