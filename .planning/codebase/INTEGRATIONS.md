# INTEGRATIONS.md

Codebase integrations map for Refuel iOS app.

---

## External APIs

### Fuel Price API
- **Status:** Not yet integrated — no live API exists
- **Seam:** `FuelPriceService` protocol in `refuel/FuelPriceService.swift`
- **Current implementation:** `MockFuelPriceService` only (stubbed data)
- **Notes:** Real API provider TBD; protocol-based design allows drop-in replacement

---

## Apple Platform Frameworks

### MapKit
- **Files:** `refuel/MapView.swift`, `refuel/SearchService.swift`
- **Usage:** Map rendering, local point-of-interest search
- **Auth/Keys:** None required

### CoreLocation — Live Location
- **File:** `refuel/LocationManager.swift`
- **API:** `CLLocationUpdate.liveUpdates()` (iOS 17+)
- **Auth/Keys:** Location usage description in Info.plist

### CoreLocation — Geofencing
- **File:** `refuel/GeofenceService.swift`
- **API:** `CLCircularRegion` monitoring
- **Auth/Keys:** Always-on or when-in-use location permission

### Vision Framework (on-device OCR)
- **File:** `refuel/OCRService.swift`
- **API:** `VNRecognizeTextRequest`
- **Notes:** Fully on-device; no network call, no API key

### VisionKit
- **Files:** `refuel/PriceBoardScannerView.swift`, `refuel/ReceiptScannerView.swift`
- **API:** `DataScannerViewController`
- **Notes:** Camera permission required; on-device only

### UserNotifications (local only)
- **File:** `refuel/NotificationManager.swift`
- **Notes:** Local notifications only — no APNs, no remote push, no backend required

### Accelerate (vDSP)
- **File:** `refuel/FuelPriceIngestor.swift`
- **Usage:** Vectorized z-score calculations for price analytics
- **Notes:** On-device math acceleration; no external dependency

---

## Navigation Deep Links

### Apple Maps
- **File:** `refuel/NavigationService.swift`
- **Scheme:** `maps.apple.com` URL scheme
- **Auth/Keys:** None

### Google Maps
- **File:** `refuel/NavigationService.swift`
- **Scheme:** `comgooglemaps://` URL scheme
- **Auth/Keys:** None (app must be installed on device)

---

## Observability

### OSLog (structured logging)
- **Subsystem:** `com.slade.refuel`
- **Notes:** On-device only; no remote log aggregation service

---

## What's NOT Present

- No authentication provider (no OAuth, no Sign in with Apple)
- No remote database (no Firebase, CloudKit, Supabase, etc.)
- No push notification backend (APNs not configured)
- No analytics SDK (no Firebase Analytics, Mixpanel, etc.)
- No crash reporting (no Crashlytics, Sentry, etc.)
- No CI/CD secrets infrastructure
- No external Swift packages (SPM lockfile is empty)
- No secrets management (no `.env`, no Keychain usage for API keys yet)
