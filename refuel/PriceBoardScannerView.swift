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
        var currentItems = Set<RecognizedItem>()
        
        init(parent: PriceBoardScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            currentItems = Set(allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            currentItems = Set(allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            currentItems = Set(allItems)
        }
        
        func capture() {
            let lines = currentItems.compactMap { item -> String? in
                if case .text(let text) = item {
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
            ZStack(alignment: .bottom) {
                PriceBoardScannerView(onCapture: { results in
                    onCapture(results)
                    dismiss()
                }, triggerCapture: $triggerCapture)
                .background(Color.black)
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("Point camera at price board")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                    
                    Button(action: {
                        triggerCapture = true
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
