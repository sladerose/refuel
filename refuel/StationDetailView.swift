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
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(station.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(station.address)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    if let zScore = station.zScore {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text(priceComparisonText(zScore: zScore))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(station.ragStatus.color.opacity(0.1))
                        .foregroundStyle(station.ragStatus.color)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Fuel Prices") {
                ForEach(station.prices.sorted(by: { $0.grade < $1.grade })) { price in
                    HStack {
                        Label {
                            Text(price.grade)
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "fuelpump.fill")
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "R%.2f", price.price))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            Section("Information") {
                if let hours = station.openingHours {
                    LabeledContent("Opening Hours") {
                        Text(hours)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let services = station.services, !services.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Services")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(services, id: \.self) { service in
                                Text(service)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("Actions") {
                Button {
                    showingScanner = true
                } label: {
                    Label("Scan Receipt", systemImage: "camera.viewfinder")
                }
                
                Button {
                    showingBoardScanner = true
                } label: {
                    Label("Scan Price Board", systemImage: "fuelpump.circle")
                }
                
                Button {
                    NavigationService.shared.open(
                        app: .appleMaps,
                        coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude),
                        label: station.name
                    )
                } label: {
                    Label("Navigate in Apple Maps", systemImage: "map")
                }
                
                Button {
                    NavigationService.shared.open(
                        app: .googleMaps,
                        coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude),
                        label: station.name
                    )
                } label: {
                    Label("Navigate in Google Maps", systemImage: "location")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    station.isFavorite.toggle()
                } label: {
                    Image(systemName: station.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(station.isFavorite ? .red : .primary)
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            ReceiptScannerView { result in
                switch result {
                case .success(let images):
                    OCRService.shared.process(images: images, stations: stations) { data in
                        var finalData = data
                        finalData.stationName = station.name
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
                gamificationManager.awardXP(amount: 30, stationName: station.name, type: "board_scan")
            }
        }
        .sheet(isPresented: $showingVerification) {
            PriceVerificationView(station: station, detectedPrices: detectedBoardPrices)
        }
    }
    
    private func priceComparisonText(zScore: Double) -> String {
        if zScore < -1.5 {
            return "Exceptional value!"
        } else if zScore < -0.5 {
            return "Good local value."
        } else if zScore <= 0.5 {
            return "Average local price."
        } else if zScore <= 1.5 {
            return "Slightly above average."
        } else {
            return "Above local average."
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
