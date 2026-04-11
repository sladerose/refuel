# Refuel

## What This Is

Refuel is an iOS app for car owners that helps them find and track the cheapest fuel prices in their area. It uses a hybrid Map/List interface with RAG (Red-Amber-Green) status indicators to visualize price comparisons within an adjustable geofenced area.

## Core Value

Users can quickly identify and navigate to the fuel station offering the best price within their preferred search radius.

## Requirements

### Validated

- [x] Initial codebase mapping completed (SwiftUI + SwiftData + Swift Testing)

### Active

- [ ] Hybrid Map/List discovery interface
- [ ] RAG price status overlays (Red-Amber-Green comparison)
- [ ] Adjustable geofenced search area
- [ ] Fuel station details (grades, opening times)
- [ ] External map navigation integration
- [ ] Refuel history log
- [ ] Favorite stations and price alerts

### Out of Scope

- [ ] Crowdsourced price updates (v1 will rely on automated or manual input)
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

---
*Last updated: 2026-04-11 after project initialization*
