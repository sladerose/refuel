# Phase 3: Value Analytics & Dynamic Discovery - Research

**Researched:** 2026-04-12
**Domain:** Value Analytics (RAG), Geofencing, MapKit Performance
**Confidence:** HIGH

## Summary

This phase focuses on the "Value Analytics" value proposition: helping users identify the best deals via visual RAG (Red-Amber-Green) indicators and ensuring data stays fresh as they travel through "Dynamic Geofencing." 

**Primary recommendations:**
1. Use **Z-scores** with **Standard Deviation** for RAG logic to ensure color scaling adjusts to current market volatility.
2. Implement **`CLMonitor`** (iOS 17+) for background-aware geofencing to trigger data refreshes.
3. Use native SwiftUI **`Marker`** with the `.tint()` modifier for up to 200 markers; switch to `UIViewRepresentable` + `MKMapView` if clustering becomes a visual requirement.
4. Perform analytics in a **`ValueAnalyticsService`** using the **Accelerate (vDSP)** framework for efficient calculation.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| CoreLocation | iOS 17.0+ | `CLMonitor` for geofencing | Modern async/await API for location monitoring. |
| MapKit | iOS 17.0+ | Map UI with dynamic Markers | Built-in SwiftUI support for markers and annotations. |
| Accelerate | 4.0+ | `vDSP` for Mean/StdDev | Highly optimized for numeric array processing (SIMD). |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftData | iOS 17.0+ | Station Persistence | Storing station data used as input for RAG calculations. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `CLMonitor` | `CLLocationManager` | Legacy delegate pattern; more boilerplate; harder to bridge to Swift Concurrency. |
| Standard Deviation | Percentiles | Percentiles ignore the "distance" between prices (e.g., top 33% might only be 0.1c different). |
| Native Map | `MKMapView` | Native Map lacks clustering but is easier to maintain in a pure SwiftUI app. |

## Architecture Patterns

### Recommended Project Structure
```
refuel/
├── Services/
│   ├── ValueAnalyticsService.swift # RAG logic & Z-score calculations
│   └── GeofenceService.swift       # CLMonitor lifecycle management
└── UI/
    └── Map/
        ├── StationMarker.swift     # Visual RAG logic for map
        └── MapViewModel.swift      # Coordination of visible markers
```

### Pattern 1: Z-Score Analytics (RAG Logic)
**What:** Calculate a Z-score for each price within a "Local Context" (e.g., all stations within 20km or visible in map).
**When to use:** Whenever the price list updates or the map's search center changes.
**Example:**
```swift
import Accelerate

func calculateRAG(prices: [Double]) -> (mean: Double, stdDev: Double) {
    let mean = vDSP.mean(prices)
    let stdDev = vDSP.standardDeviation(prices)
    return (mean, stdDev)
}

func colorFor(price: Double, mean: Double, stdDev: Double) -> Color {
    let zScore = (price - mean) / (stdDev > 0 ? stdDev : 1.0)
    switch zScore {
        case ..<(-1.5): return .darkGreen  // Exceptional
        case ..<(-0.5): return .green      // Good
        case (-0.5)...0.5: return .yellow  // Average
        case 0.5...1.5: return .orange     // Expensive
        default: return .red               // Avoid
    }
}
```

### Anti-Patterns to Avoid
- **Recalculating in `body`:** Never perform Mean/SD calculations directly in the SwiftUI `body` of a View; it will throttle the UI during scrolls/zooms.
- **Global Averages:** Avoid calculating RAG based on a nationwide average. Fuel prices are hyper-local; a "good" price in London is "bad" in a rural area.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Array Statistics | Custom `reduce` loops | `vDSP` (Accelerate) | SIMD hardware acceleration; handles precision edge cases better. |
| Geofence State | Custom background timer | `CLMonitor` | System-level power-efficient monitoring that wakes the app on exit. |
| Clustering Logic | Custom math | `MKMapView` (Representable) | If clustering is required, use the system's optimized native implementation. |

## Common Pitfalls

### Pitfall 1: CLMonitor "False Exits" on iOS 18
**What goes wrong:** App receives a region exit event immediately upon starting monitoring.
**How to avoid:** Use `CLServiceSession` and ensure the `assumedState` is correctly initialized based on current user location before adding the condition.

### Pitfall 2: Low Variance RAG
**What goes wrong:** When all prices in an area are identical (e.g., a price war), `stdDev` is 0, leading to Division by Zero or everything being "Red".
**How to avoid:** Add a `minimumVariance` floor (e.g., if SD < 0.01, treat all as "Yellow").

## Code Examples

### Dynamic Geofencing with CLMonitor
```swift
// Source: [Verified: WWDC23 Build location-aware apps with Core Location]
import CoreLocation

actor GeofenceManager {
    let monitor = await CLMonitor("StationRefreshMonitor")
    
    func startMonitoring(center: CLLocationCoordinate2D, radius: CLLocationDistance) async {
        let condition = CLMonitor.CircularCondition(
            center: center,
            radius: radius
        )
        await monitor.add(condition, identifier: "search_radius", assumedState: .satisfied)
        
        for try await event in await monitor.events {
            if event.identifier == "search_radius" && event.state == .unsatisfied {
                // User moved out of range -> Trigger Refresh
                await triggerDataRefresh()
                // Update Geofence to new center
                await startMonitoring(center: event.location.coordinate, radius: radius)
            }
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `CLLocationManagerDelegate` | `CLMonitor` | iOS 17.0 | Cleaner async code; better power management for regions. |
| `MapMarker` (legacy) | `Marker` | iOS 17.0 | Better performance in SwiftUI Maps; custom tints. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SwiftData doesn't support aggregate functions | Local Average Logic | Higher memory usage if we fetch 1000s of objects to calculate mean. |
| A2 | Native Map lacks clustering | Map Performance | May need `UIViewRepresentable` refactor if clutter is too high. |

## Open Questions

1. **Wait, does the price API provide its own averages?**
   - Recommendation: Use local client-side calculation to ensure "Local" matches exactly what the user sees on their map.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| CoreLocation | Geofencing | ✓ | 17.0+ | — |
| MapKit | Map UI | ✓ | 17.0+ | — |
| Accelerate | RAG Math | ✓ | 4.0+ | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing |
| Config file | default |
| Quick run command | `swift test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INFO-02 | Price color is Green when Z-score < -1.5 | unit | `swift test --filter AnalyticsTests` | ❌ Wave 0 |
| DISCO-03 | CLMonitor events trigger a service refresh | integration | `swift test --filter GeofenceTests` | ❌ Wave 0 |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Validate API price data is positive numeric before calculation. |
| V6 Cryptography | no | No sensitive encryption required in this phase. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Location Spoofing | Tampering | Check location timestamp and accuracy before triggering geofence refreshes. |

## Sources

### Primary (HIGH confidence)
- Apple Documentation (CLMonitor) - [iOS 17+ Location APIs]
- Apple Documentation (vDSP) - [Accelerate Framework Statistical Functions]
- WWDC 2023 - [Build location-aware apps with Core Location]

### Secondary (MEDIUM confidence)
- StackOverflow / Community forums - [SwiftUI Map clustering limitations]
