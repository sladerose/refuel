# Roadmap: Refuel

## Phases

- [x] **Phase 1: Core Map & Location Infrastructure** - Foundation for spatial UI, user location tracking, and external navigation. (completed 2026-04-11)
- [x] **Phase 2: Price Integration & Persistence** - External API integration, SwiftData persistence, and sortable list discovery. (completed 2026-04-11)
- [x] **Phase 3: Value Analytics & Dynamic Discovery** - RAG status logic, price comparisons, and geofence-triggered refreshes. (completed 2026-04-12)
- [x] **Phase 4: Personalization & Cost Tracking** - Favorite stations management and refuel history logging. (completed 2026-04-12)
- [x] **Phase 5: Project Polish & Final Verification** - Closing feature gaps, navigation wiring, and detailed information rendering. (completed 2026-04-12)
- [ ] **Phase 6: The Vision System** - OCR for fuel receipts and price board recognition using VisionKit.
- [ ] **Phase 7: The Engagement Engine** - Gamification layer including streaks, XP, ranks, and user profiles.
- [ ] **Phase 8: Proactive Intelligence** - Dwell detection, proactive verifications, and CEF predictive hike alerts.
- [ ] **Phase 9: Rewards Hub & Social Proof** - Lottery system, sharing stats, and community impact visualization.

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
  1. User can view a list of stations sorted by distance or fuel price. ✓
  2. User can view detailed fuel grade prices and opening hours for any station. ✓
  3. Data fetched from the API is cached in SwiftData for offline/immediate access. ✓
**Plans**: 02-01-PLAN.md, 02-02-PLAN.md
**UI hint**: yes

### Phase 3: Value Analytics & Dynamic Discovery
**Goal**: Implement the RAG (Red-Amber-Green) value proposition and ensure data stays fresh as the user moves.
**Requirements**: DISCO-03, INFO-02
**Success Criteria** (what must be TRUE):
  1. Map markers and list items are color-coded (R/A/G) based on price relative to the local average. ✓
  2. The app automatically fetches new station data when the user moves outside the current search geofence. ✓
  3. User can instantly identify the cheapest station in their current view via visual highlighting. ✓
**Plans**: 
- [x] 03-01-PLAN.md — Value Analytics & UI Visualization
- [x] 03-02-PLAN.md — Dynamic Discovery & Geofencing
**UI hint**: yes

### Phase 4: Personalization & Cost Tracking
**Goal**: Allow users to build a personal profile of favorite stations and track their actual fuel spending.
**Depends on**: Phase 2
**Requirements**: TRACK-01, TRACK-02
**Success Criteria** (what must be TRUE):
  1. User can save/remove stations to a "Favorites" list for quick access. ✓
  2. User can manually log a fuel purchase (date, volume, price, station). ✓
  3. User can view a history of their refuels with calculated total spend. ✓
**Plans**: 04-01-PLAN.md, 04-02-PLAN.md
**UI hint**: yes

### Phase 5: Project Polish & Final Verification
**Goal**: Bridge UI gaps, wire navigation, and ensure all success criteria are fully met.
**Requirements**: INFO-03, INFO-04
**Success Criteria** (what must be TRUE):
  1. User can see opening hours and services for any station. ✓
  2. External navigation triggers are functional from both map and list views. ✓
  3. Project state reflects 100% completion across all requirements. ✓
  4. UI meets modern standards for accessibility and feedback. ✓
**Plans**: 05-01-PLAN.md, 05-02-PLAN.md
**UI hint**: yes

### Phase 6: The Vision System
**Goal**: Eliminate data entry friction by allowing users to scan receipts and price boards.
**Depends on**: Phase 4
**Requirements**: VISION-01, VISION-02
**Success Criteria**:
  1. User can snap a photo of a fuel receipt and have it automatically populate a `RefuelEvent`. ✓
  2. User can capture a station's price board to update global prices.
  3. OCR accuracy is >90% for standard South African fuel slips.
**Plans**: 2 plans
- [x] 06-01-PLAN.md — Receipt OCR Scanner
- [ ] 06-02-PLAN.md — Price Board Recognition
**UI hint**: yes

### Phase 7: The Engagement Engine
**Goal**: Drive long-term retention using "Duolingo-style" gamification.
**Depends on**: Phase 6
**Success Criteria**:
  1. User profile tracks XP, Ranks, and "Fuel Streaks."
  2. "Streak" system incentivizes at least one contribution every 10 days.
  3. Users see "Community Impact" stats (e.g., "You saved others R500").

### Phase 8: Proactive Intelligence
**Goal**: Proactively prompt users for data based on location and external events.
**Depends on**: Phase 3
**Success Criteria**:
  1. App detects when a user is "Dwellling" at a fuel station and sends a verification prompt.
  2. App sends "Hike Alerts" 24 hours before regulated price changes using CEF data.
  3. Automated follow-ups for forgotten scans after a station visit.

### Phase 9: Rewards Hub & Social Proof
**Goal**: Close the loop with tangible rewards and social sharing.
**Depends on**: Phase 7, 8
**Success Criteria**:
  1. Automated entry into "Tank-a-Month" lottery for every valid scan.
  2. Users can share their "Savings Achievement" cards to social media.
  3. Visual dashboard of community-wide fuel savings.

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Map & Location | 1/1 | Completed | 2026-04-11 |
| 2. Price Integration | 2/2 | Complete | 2026-04-11 |
| 3. Value Analytics | 2/2 | Complete | 2026-04-12 |
| 4. Cost Tracking | 2/2 | Complete | 2026-04-12 |
| 5. Project Polish | 2/2 | Complete | 2026-04-12 |
| 6. Vision System | 1/2 | In Progress | - |
| 7. Engagement Engine | 0/1 | Not Started | - |
| 8. Proactive Intelligence | 0/1 | Not Started | - |
| 9. Rewards & Social | 0/1 | Not Started | - |
