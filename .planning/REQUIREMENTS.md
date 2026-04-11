# Requirements: Refuel

**Defined:** 2026-04-11
**Core Value:** Users can quickly identify and navigate to the fuel station offering the best price within their preferred search radius.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Discovery (DISCO)

- [ ] **DISCO-01**: User can view nearby fuel stations on an interactive map.
- [ ] **DISCO-02**: User can view a sortable list of fuel stations (price/distance).
- [ ] **DISCO-03**: Map/List automatically refreshes as the user moves (Dynamic Geofencing).
- [ ] **DISCO-04**: User can search for fuel stations by specific location or address.

### Station Information (INFO)

- [ ] **INFO-01**: User can view current prices for multiple fuel grades at a station.
- [ ] **INFO-02**: User can instantly see a station's price value via RAG (Red-Amber-Green) indicators.
- [ ] **INFO-03**: User can view station details including opening times and available services.
- [ ] **INFO-04**: User can open a station's location in Apple Maps or Google Maps for navigation.

### Personalization & Tracking (TRACK)

- [ ] **TRACK-01**: User can log individual refuel events to track costs over time.
- [ ] **TRACK-02**: User can save favorite fuel stations for quick access.

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
| DISCO-01 | Phase 1 | Pending |
| DISCO-02 | Phase 2 | Pending |
| DISCO-03 | Phase 3 | Pending |
| DISCO-04 | Phase 1 | Pending |
| INFO-01 | Phase 2 | Pending |
| INFO-02 | Phase 3 | Pending |
| INFO-03 | Phase 2 | Pending |
| INFO-04 | Phase 1 | Pending |
| TRACK-01 | Phase 4 | Pending |
| TRACK-02 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-11*
*Last updated: 2026-04-11 after initial definition*
