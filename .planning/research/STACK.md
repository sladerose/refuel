# Technology Stack

**Project:** Refuel (iOS Fuel Tracker)
**Researched:** 2024-05-24

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **SwiftUI** | 6.0 (iOS 18) | UI Framework | Declarative, optimized for modern MapKit and high-performance list rendering. |
| **Swift** | 6.0 | Language | Use of Task/Actor model for safe background updates and concurrency. |

### Database & Persistence
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **SwiftData** | 1.0+ | Local Persistence | Native integration with SwiftUI; simpler schema management than CoreData. |

### Infrastructure & Services
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **MapKit** | iOS 17+ | Mapping & Search | Native `Map` view with `Marker` support and `MapCameraPosition` state management. |
| **Core Location** | iOS 17+ | Proximity/Geofencing | `CLLocationUpdate.liveUpdates` provides async stream of location events. |
| **BackgroundTasks** | iOS 13+ | Price Sync | `BGAppRefreshTask` for opportunistic background price updates. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Foundation** | Standard | Networking | `URLSession` for API calls (async/await). |
| **Swift Testing** | Standard | Unit/UI Testing | Modern testing framework integrated into Xcode. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| **Mapping** | SwiftUI `Map` | `MKMapView` (UIKit) | SwiftUI `Map` is easier to manage in iOS 17+. Fallback to `MKMapView` only if clustering 1000+ points is required. |
| **Persistence** | SwiftData | SQLite.swift | SwiftData is more idiomatic for SwiftUI and handles model relationships more easily. |
| **State Mgmt** | `@Observable` | TCA (The Composable Architecture) | `@Observable` is built-in and sufficient for this scope. TCA adds significant boilerplate. |

## Installation

```bash
# Core (Standard Xcode Project)
# No external package managers required for core stack.
```

## Sources

- [Apple Developer: What's new in SwiftUI (WWDC24)](https://developer.apple.com/wwdc24/10146)
- [Apple Developer: Meet SwiftData](https://developer.apple.com/wwdc23/10187)
- [Apple Developer: Meet MapKit for SwiftUI](https://developer.apple.com/wwdc23/10043)
