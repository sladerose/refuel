import Foundation
import Accelerate

@Observable
final class ValueAnalyticsService {
    func calculateAnalytics(for stations: [Station]) {
        // Only consider stations with prices and non-zero prices (to mitigate T-03-01)
        let validData = stations.compactMap { station -> (Station, Double)? in
            guard let minPrice = station.prices.map(\.price).min(), minPrice > 0 else {
                return nil
            }
            return (station, minPrice)
        }
        
        // Reset zScore for stations without valid prices
        let validStationIds = Set(validData.map { $0.0.id })
        for station in stations {
            if !validStationIds.contains(station.id) {
                station.zScore = nil
            }
        }
        
        guard validData.count >= 1 else { return }
        
        if validData.count == 1 {
            validData[0].0.zScore = 0
            return
        }
        
        let prices = validData.map { $0.1 }
        let n = vDSP_Length(prices.count)
        
        var mean = 0.0
        vDSP_meanvD(prices, 1, &mean, n)
        
        var variance = 0.0
        var negativeMean = -mean
        var differences = [Double](repeating: 0.0, count: prices.count)
        vDSP_vsaddD(prices, 1, &negativeMean, &differences, 1, n)
        
        var squaredDifferences = [Double](repeating: 0.0, count: prices.count)
        vDSP_vsqD(differences, 1, &squaredDifferences, 1, n)
        vDSP_meanvD(squaredDifferences, 1, &variance, n)
        
        let stdDev = sqrt(variance)
        
        if stdDev == 0 {
            for (station, _) in validData {
                station.zScore = 0
            }
        } else {
            for (station, minPrice) in validData {
                station.zScore = (minPrice - mean) / stdDev
            }
        }
    }
}
