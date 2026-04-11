# Feature Landscape

**Domain:** iOS Fuel Tracker
**Researched:** 2024-05-24

## Table Stakes

Features users expect in any mapping/price tracker app.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Interactive Map** | Standard discovery pattern. | Medium | Use SwiftUI `Map` (iOS 17+). |
| **Search by Radius** | Need to find local fuel. | Low | Use `CLLocation` for distance math. |
| **Fuel Grades/Prices** | Core utility. | Low | Requires a reliable data source. |
| **Route Navigation** | Must be able to go to the station. | Low | External link to Maps/Google Maps. |

## Differentiators

Features that set Refuel apart.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **RAG Indicators** | Instant visual comparison of price value (Cheap/Average/Expensive). | Medium | Requires statistical analysis of regional prices. |
| **Dynamic Geofencing** | Automatically refreshes prices as user moves without manual search. | High | Uses `CLBackgroundActivitySession` and background tasks. |
| **Price Alert Subscriptions** | Notifies user when a favorite station drops below a price or becomes the cheapest in the area. | High | Requires background price polling and `UNUserNotificationCenter`. |
| **Offline Cache** | Shows last known prices when no connectivity. | Low | Handled natively by SwiftData. |

## Anti-Features

Features to explicitly NOT build to maintain focus and performance.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **In-app Navigation** | Too complex to build and maintain (Route turn-by-turn). | Deep-link to Apple/Google Maps. |
| **User Crowdsourcing** | High friction, requires moderation, prone to spam. | Use automated API/Data sources. |
| **Fuel Loyalty Cards** | Complex integrations with many providers. | Allow users to add "Favorite" tags to stations they have cards for. |

## Feature Dependencies

```
Location Permissions → Map Rendering → Fuel Price Fetching → RAG Indicators
```

## MVP Recommendation

Prioritize:
1. **Hybrid Map/List Discovery**: Fundamental UI.
2. **Real-time Price Fetching**: Core utility.
3. **RAG Status indicators**: Primary differentiator.
4. **External Navigation**: Completes the user journey.

Defer:
- **Price Alerts**: Significant background engineering required.
- **Refuel History Log**: Second-order utility.

## Sources

- [Market Research: GasBuddy / PetrolPrices / Fuelio](https://www.gasbuddy.com/)
- [Apple Developer: Location Services Guide](https://developer.apple.com/documentation/corelocation)
