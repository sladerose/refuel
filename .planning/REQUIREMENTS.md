# Requirements: Refuel

**Defined:** 2026-04-11
**Core Value:** Users can quickly identify and navigate to the fuel station offering the best price within their preferred search radius.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Discovery (DISCO)

- [x] **DISCO-01**: User can view nearby fuel stations on an interactive map.
- [x] **DISCO-02**: User can view a sortable list of fuel stations (price/distance).
- [x] **DISCO-03**: Map/List automatically refreshes as the user moves (Dynamic Geofencing).
- [x] **DISCO-04**: User can search for fuel stations by specific location or address.

### Station Information (INFO)

- [x] **INFO-01**: User can view current prices for multiple fuel grades at a station.
- [x] **INFO-02**: User can instantly see a station's price value via RAG (Red-Amber-Green) indicators.
- [x] **INFO-03**: User can view station details including opening times and available services.
- [x] **INFO-04**: User can open a station's location in Apple Maps or Google Maps for navigation.

### Personalization & Tracking (TRACK)

- [x] **TRACK-01**: User can log individual refuel events to track costs over time.
- [x] **TRACK-02**: User can save favorite fuel stations for quick access.

### Vision (VISION)

- [x] **VISION-01**: User can scan a fuel receipt to automatically populate a refuel event.
- [x] **VISION-02**: User can capture a station's price board to update global prices.

### Engagement (ENGAGE)

- [ ] **ENGAGE-01**: User can track personal contribution stats (XP, Ranks, Streaks).
- [ ] **ENGAGE-02**: User is incentivized to contribute every 10 days via a "Fuel Streak" system.
- [ ] **ENGAGE-03**: User can view "Community Impact" metrics (savings for others).

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Personalization & Tracking

- **TRACK-03**: User receives notifications when prices at favorite stations drop below a threshold.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Crowdsourced prices | High risk of spam/inaccuracy for v1; better to start with official data. |
| In-app Payment | High complexity and security overhead; use external maps for navigation instead. |
| Vehicle Maintenance | Out of core scope (price discovery); can be added as a separate app/module. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DISCO-01 | Phase 1 | Complete |
| DISCO-02 | Phase 2 | Complete |
| DISCO-03 | Phase 3 | Complete |
| DISCO-04 | Phase 1 | Complete |
| INFO-01 | Phase 2 | Complete |
| INFO-02 | Phase 3 | Complete |
| INFO-03 | Phase 2 | Complete |
| INFO-04 | Phase 1 | Complete |
| TRACK-01 | Phase 4 | Complete |
| TRACK-02 | Phase 4 | Complete |
| VISION-01 | Phase 6 | Complete |
| VISION-02 | Phase 6 | Complete |
| ENGAGE-01 | Phase 7 | Planned |
| ENGAGE-02 | Phase 7 | Planned |
| ENGAGE-03 | Phase 7 | Planned |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-11*
*Last updated: 2026-04-12 after Phase 7 planning*
