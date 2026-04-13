# Refuel

## What This Is

Refuel is an iOS app for car owners that helps them find and track the cheapest fuel prices in their area. It uses a hybrid Map/List interface with RAG (Red-Amber-Green) status indicators to visualize price comparisons within an adjustable geofenced area.

## Core Value

Users can quickly identify and navigate to the fuel station offering the best price within their preferred search radius.

## Requirements

### Completed (v1–v3)

- [x] Hybrid Map/List discovery interface with RAG (Red-Amber-Green) price overlays
- [x] Adjustable geofenced search area with dynamic refresh
- [x] Fuel station details (grades, opening times, navigation)
- [x] External map navigation (Apple Maps + Google Maps)
- [x] Refuel history log and favorite stations
- [x] Receipt OCR (VisionKit) for auto-populated refuel events
- [x] Price board OCR for live station price capture
- [x] Gamification — XP, Ranks, Streaks, Community Impact metrics
- [x] Dwell detection and proactive price verification prompts
- [x] Predictive hike alerts (24h before CEF price changes)
- [x] Lucky Draw lottery and social sharing (Rewards Hub)
- [x] CloudKit private database sync (`iCloud.com.refuel.app`) across user devices

### Active (v3)

- [ ] Global Community Sync — public CloudKit leaderboard (Phase 12)
- [ ] Live Data Ingestion — production Fuel SA API + BGAppRefreshTask (Phase 13)
- [ ] Station Verification Crowdsourcing — community consensus voting (Phase 14)

### Out of Scope

- [ ] Crowdsourced price spam — mitigated via verification consensus (Phase 14)
- [ ] In-app payment for fuel
- [ ] Vehicle maintenance tracking

## Context

- The project is a standard SwiftUI 6.0/iOS 18 template.
- Persistence is handled by SwiftData.
- Testing is handled by the Swift Testing framework.
- The app should be optimized for performance in map rendering and price calculations.

## Constraints

- **Platform**: iOS 18+ (SwiftUI, MapKit, SwiftData)
- **Data Source**: External fuel price API (TBD)
- **Permissions**: Location services required for proximity features

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| SwiftUI/SwiftData | Using modern Apple frameworks for maximum efficiency and longevity. | ✓ Good |
| External Navigation | Offloading navigation to dedicated apps (Maps/Google Maps) reduces complexity and maintenance. | ✓ Good |
| ModelActor for sync | Thread-safe background price syncing without manual locking. | ✓ Good |
| System text styles | HIG-compliant dynamic type instead of fixed point sizes. | ✓ Good |
| `cloudKitDatabase: .automatic` | SwiftData manages CloudKit sync transparently against `iCloud.com.refuel.app` private DB. | ✓ Good |
| Private DB only (v3 Phase 11) | Public/shared zones deferred to Phase 12 to reduce entitlement complexity at launch. | ✓ Good |

---
*Last updated: 2026-04-13 after Phase 11 (Cloud Foundation) complete*
