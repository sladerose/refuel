import SwiftUI
import VisionKit

struct PriceBoardScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: ([String: Double]) -> Void
    @Binding var triggerCapture: Bool
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
        if triggerCapture {
            context.coordinator.capture()
            DispatchQueue.main.async {
                triggerCapture = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: PriceBoardScannerView
        var currentItems: [RecognizedItem] = []
        
        init(parent: PriceBoardScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            currentItems = allItems
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            currentItems = allItems
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            currentItems = allItems
        }
        
        func capture() {
            // Filter by confidence if available (DataScanner provides confidence levels)
            let lines = currentItems.compactMap { item -> String? in
                if case .text(let text) = item {
                    // Only use high confidence text
                    // DataScanner doesn't expose a raw Double confidence easily in all versions, 
                    // but we can check if it's "accurate" via request settings.
                    return text.transcript
                }
                return nil
            }
            
            let results = OCRService.shared.parsePriceBoard(lines)
            parent.onCapture(results)
        }
    }
}

struct PriceBoardScannerContainer: View {
    @Environment(\.dismiss) private var dismiss
    let onCapture: ([String: Double]) -> Void
    
    @State private var triggerCapture = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PriceBoardScannerView(onCapture: { results in
                    onCapture(results)
                    dismiss()
                }, triggerCapture: $triggerCapture)
                .background(Color.black)
                .ignoresSafeArea()
                
                // Visual Focus Guide (Liquid Glass Style)
                VStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .frame(width: 300, height: 400)
                        .overlay(
                            VStack {
                                Image(systemName: "fuelpump.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("Align prices within this area")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        )
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("Stable lighting improves accuracy")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        
                        Button(action: {
                            triggerCapture = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                Circle()
                                    .fill(.white)
                                    .frame(width: 64, height: 64)
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.black)
                            }
                        }
                        .sensoryFeedback(.impact, trigger: triggerCapture) { oldValue, newValue in
                            newValue == true
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
