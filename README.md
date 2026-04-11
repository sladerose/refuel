# Refuel ⛽️

**Refuel** is a modern iOS application designed to help drivers find the best fuel prices in their area instantly. Using real-time location tracking and SIMD-optimized price analytics, Refuel visualizes local price competitiveness through an intuitive RAG (Red-Amber-Green) interface.

## 🚀 v2: The Engagement Engine

Refuel v2 transforms data entry into a community-driven habit through the **Engagement Engine**:

- **Frictionless Ingestion**:
  - **Receipt OCR**: Snap a photo of your fuel slip using **VisionKit** to auto-populate refuel logs and update station prices.
  - **Price Board Capture**: Capture live outdoor signage prices using real-time OCR.
- **"Duolingo for Fuel" Gamification**:
  - **XP & Ranks**: Earn rewards for every contribution. Progress from Newcomer to Fuel Legend.
  - **Fuel Streaks**: Maintain a 10-day streak to stay at the top of your game.
  - **Community Impact**: See how much you've saved your neighbors in Rand.
- **Proactive Intelligence**:
  - **Dwell Detection**: Automatically prompted to verify prices when you stop at a station.
  - **Hike Alerts**: Predictive alerts 24 hours before regulated price changes.
- **Rewards Hub**:
  - **Tank-a-Month Lottery**: Every contribution is an entry into a monthly fuel prize draw.
  - **Achievement Cards**: Share your savings and status directly to social media.

## 📱 Core Features

- **Hybrid Discovery**: Switch seamlessly between a high-performance **MapKit** interface and a detailed, sortable **Station List**.
- **Value Analytics**: Advanced Z-score calculations using the **Accelerate (vDSP)** framework.
- **Multi-App Navigation**: One-tap navigation support for both **Apple Maps** and **Google Maps**.
- **Modern Architecture**: Built with **Swift 6**, **SwiftUI**, and **SwiftData**.

## 🛠 Tech Stack

- **Language**: Swift 6.0 (Strict Concurrency)
- **UI Framework**: SwiftUI 6.0
- **Persistence**: SwiftData
- **Vision**: VisionKit & Vision Framework
- **Spatial**: MapKit & CoreLocation
- **Mathematics**: Accelerate (vDSP) for high-performance SIMD analytics
- **Notifications**: UserNotifications with deep link support

## 📱 Requirements

- **iOS 18.0+**
- **Xcode 16.0+**
- **Location Services**: Required for real-time proximity and geofencing features.
- **Camera Access**: Required for receipt and price board scanning.

## 📦 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/sladerose/refuel.git
   ```
2. Open `refuel.xcodeproj` in Xcode 16+.
3. Select an iOS 18+ simulator or a physical device.
4. Build and Run (**⌘R**).

---
*Refuel: Beat the Hike. Save Together.*
*Created with ❤️ by Slade Rose*
