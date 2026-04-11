import SwiftUI
import SwiftData
import CoreLocation

struct StationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GamificationManager.self) private var gamificationManager
    @Query private var stations: [Station]
    let station: Station
    
    @State private var showingScanner = false
    @State private var showingBoardScanner = false
    @State private var showingAddLog = false
    @State private var showingVerification = false
    @State private var scannedData: ScannedReceiptData?
    @State private var detectedBoardPrices: [String: Double] = [:]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(station.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(station.address)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        station.isFavorite.toggle()
                    } label: {
                        Image(systemName: station.isFavorite ? "heart.fill" : "heart")
                            .font(.title)
                            .foregroundColor(station.isFavorite ? .red : .gray)
                            .padding(10)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                // RAG Status & Price Comparison
                if let zScore = station.zScore {
                    HStack {
                        Image(systemName: "info.circle.fill")
                        Text(priceComparisonText(zScore: zScore))
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(station.ragStatus.color.opacity(0.1))
                    .foregroundColor(station.ragStatus.color)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Opening Hours
                if let hours = station.openingHours {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Opening Hours", systemImage: "clock")
                            .font(.headline)
                        Text(hours)
                            .font(.body)
                    }
                    .padding(.horizontal)
                }
                
                // Services
                if let services = station.services, !services.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Services", systemImage: "wrench.and.screwdriver")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(services, id: \.self) { service in
                                Text(service)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Prices
                VStack(alignment: .leading, spacing: 12) {
                    Label("Current Prices", systemImage: "fuelpump")
                        .font(.headline)
                    
                    ForEach(station.prices.sorted(by: { $0.grade < $1.grade })) { price in
                        HStack {
                            Text(price.grade)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Text(String(format: "$%.2f", price.price))
                                .font(.body)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Navigation Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingScanner = true
                    }) {
                        Label("Scan Receipt", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingBoardScanner = true
                    }) {
                        Label("Scan Price Board", systemImage: "fuelpump.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        NavigationService.shared.open(
                            app: .appleMaps,
                            coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude),
                            label: station.name
                        )
                    }) {
                        Label("Navigate in Apple Maps", systemImage: "map")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        NavigationService.shared.open(
                            app: .googleMaps,
                            coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude),
                            label: station.name
                        )
                    }) {
                        Label("Navigate in Google Maps", systemImage: "location")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingScanner) {
            ReceiptScannerView { result in
                switch result {
                case .success(let images):
                    OCRService.shared.process(images: images, stations: stations) { data in
                        var finalData = data
                        finalData.stationName = station.name // Pre-fill current station
                        self.scannedData = finalData
                        self.showingAddLog = true
                    }
                case .failure(let error):
                    print("Scanner failed: \(error)")
                }
            }
        }
        .sheet(isPresented: $showingAddLog) {
            AddRefuelLogView(stations: stations, initialData: scannedData)
        }
        .sheet(isPresented: $showingBoardScanner) {
            PriceBoardScannerContainer { results in
                self.detectedBoardPrices = results
                self.showingVerification = true
                gamificationManager.awardXP(amount: 30, stationName: station.name, type: "board_scan") // Award for capturing board
            }
        }
        .sheet(isPresented: $showingVerification) {
            PriceVerificationView(station: station, detectedPrices: detectedBoardPrices)
        }
    }
    
    private func priceComparisonText(zScore: Double) -> String {
        if zScore < -1.5 {
            return "Exceptional value! This is one of the cheapest stations in the area."
        } else if zScore < -0.5 {
            return "Good value. Prices are significantly lower than average."
        } else if zScore <= 0.5 {
            return "Average price for this area."
        } else if zScore <= 1.5 {
            return "Slightly more expensive than average."
        } else {
            return "Expensive. Consider checking other stations for better deals."
        }
    }
}

// Simple FlowLayout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX)
        }
        
        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
