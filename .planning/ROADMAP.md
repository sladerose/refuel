# Roadmap: Refuel

## Phases

- [x] **Phase 1: Core Map & Location Infrastructure** - Foundation for spatial UI, user location tracking, and external navigation.
- [x] **Phase 2: Price Integration & Persistence** - External API integration, SwiftData persistence, and sortable list discovery. (completed 2026-04-11)
- [ ] **Phase 3: Value Analytics & Dynamic Discovery** - RAG status logic, price comparisons, and geofence-triggered refreshes.
- [ ] **Phase 4: Personalization & Cost Tracking** - Favorite stations management and refuel history logging.

## Phase Details

### Phase 1: Core Map & Location Infrastructure
**Goal**: Establish the base spatial interface where users can see themselves and find station locations.
**Depends on**: Nothing
**Requirements**: DISCO-01, DISCO-04, INFO-04
**Success Criteria** (what must be TRUE):
  1. User can see their real-time location on a native SwiftUI Map. ✓
  2. User can search for a location by name/address and see the map update to that area. ✓
  3. User can tap a station marker and trigger navigation in Apple Maps or Google Maps. ✓
**Plans**: phase-1-core-map-and-location.md
**UI hint**: yes

### Phase 2: Price Integration & Persistence
**Goal**: Connect to fuel price data and allow users to browse and sort stations by real-world costs.
**Depends on**: Phase 1
**Requirements**: DISCO-02, INFO-01, INFO-03
**Success Criteria** (what must be TRUE):
  1. User can view a list of stations sorted by distance or fuel price.
  2. User can view detailed fuel grade prices and opening hours for any station.
  3. Data fetched from the API is cached in SwiftData for offline/immediate access.
**Plans**: 02-01-PLAN.md, 02-02-PLAN.md
**UI hint**: yes

### Phase 3: Value Analytics & Dynamic Discovery
**Goal**: Implement the RAG (Red-Amber-Green) value proposition and ensure data stays fresh as the user moves.
**Requirements**: DISCO-03, INFO-02
**Success Criteria** (what must be TRUE):
  1. Map markers and list items are color-coded (R/A/G) based on price relative to the local average.
  2. The app automatically fetches new station data when the user moves outside the current search geofence.
  3. User can instantly identify the cheapest station in their current view via visual highlighting.
**Plans**: 
- [ ] 03-01-PLAN.md — Value Analytics & UI Visualization
- [ ] 03-02-PLAN.md — Dynamic Discovery & Geofencing
**UI hint**: yes

### Phase 4: Personalization & Cost Tracking
**Goal**: Allow users to build a personal profile of favorite stations and track their actual fuel spending.
**Depends on**: Phase 2
**Requirements**: TRACK-01, TRACK-02
**Success Criteria** (what must be TRUE):
  1. User can save/remove stations to a "Favorites" list for quick access.
  2. User can manually log a fuel purchase (date, volume, price, station).
  3. User can view a history of their refuels with calculated total spend.
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Map & Location | 1/1 | Completed | 2026-04-11 |
| 2. Price Integration | 2/2 | Complete   | 2026-04-11 |
| 3. Value Analytics | 0/2 | In Progress | - |
| 4. Cost Tracking | 0/0 | Not started | - |
