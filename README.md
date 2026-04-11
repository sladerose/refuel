# Refuel ⛽️

**Refuel** is a modern iOS application designed to help drivers find the best fuel prices in their area instantly. Using real-time location tracking and SIMD-optimized price analytics, Refuel visualizes local price competitiveness through an intuitive RAG (Red-Amber-Green) interface.

## 🚀 Features

- **Hybrid Discovery**: Switch seamlessly between a high-performance **MapKit** interface and a detailed, sortable **Station List**.
- **Value Analytics**: Advanced Z-score calculations using the **Accelerate (vDSP)** framework to determine local price competitiveness.
- **Dynamic Geofencing**: Background monitoring via `CLLocationManager` that automatically triggers price refreshes as you move.
- **Personalization**:
  - **Favorites**: Save frequently visited stations for one-tap access.
  - **Refuel History**: Log your purchases and track your total spending over time.
- **Multi-App Navigation**: One-tap navigation support for both **Apple Maps** and **Google Maps**.
- **Modern Architecture**: Built with **Swift 6**, **SwiftUI**, and **SwiftData** for robust performance and persistence.

## 🛠 Tech Stack

- **Language**: Swift 6.0 (Strict Concurrency)
- **UI Framework**: SwiftUI 6.0
- **Persistence**: SwiftData
- **Spatial**: MapKit & CoreLocation
- **Mathematics**: Accelerate (vDSP) for high-performance SIMD analytics
- **Testing**: Swift Testing & XCTest

## 📱 Requirements

- **iOS 18.0+**
- **Xcode 16.0+**
- **Location Services**: Required for real-time proximity and geofencing features.

## 📦 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/sladerose/refuel.git
   ```
2. Open `refuel.xcodeproj` in Xcode 16+.
3. Select an iOS 18+ simulator or a physical device.
4. Build and Run (**⌘R**).

## 🗺 Roadmap

- [x] v1.0: Core discovery, RAG analytics, and cost tracking.
- [ ] v1.1: Price drop notifications for favorite stations.
- [ ] v1.2: CSV export for refuel history.

---
*Created with ❤️ by Slade Rose*
