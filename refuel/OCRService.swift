//
//  OCRService.swift
//  refuel
//
//  Created by GSD on 2026/04/11.
//

import Vision
import UIKit
import SwiftData

struct ScannedReceiptData {
    var stationName: String?
    var date: Date?
    var amountInLitres: Double?
    var pricePerLitre: Double?
    var totalCost: Double?
    var grade: String?
}

class OCRService {
    static let shared = OCRService()
    
    func process(images: [UIImage], stations: [Station], completion: @escaping (ScannedReceiptData) -> Void) {
        var allRecognizedText = [String]()
        let group = DispatchGroup()
        
        for image in images {
            guard let cgImage = image.cgImage else { continue }
            group.enter()
            
            let request = VNRecognizeTextRequest { (request, error) in
                defer { group.leave() }
                if let observations = request.results as? [VNRecognizedTextObservation] {
                    for observation in observations {
                        if let topCandidate = observation.topCandidates(1).first {
                            allRecognizedText.append(topCandidate.string)
                        }
                    }
                }
            }
            
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("Failed to perform OCR: \(error)")
                }
            }
        }
        
        group.notify(queue: .main) {
            let data = self.parseText(allRecognizedText, stations: stations)
            completion(data)
        }
    }
    
    private func parseText(_ lines: [String], stations: [Station]) -> ScannedReceiptData {
        var data = ScannedReceiptData()
        
        // Basic extraction logic to be refined in Task 2
        for line in lines {
            let lowercased = line.lowercased()
            
            // Try to find station name
            if data.stationName == nil {
                for station in stations {
                    if lowercased.contains(station.name.lowercased()) {
                        data.stationName = station.name
                        break
                    }
                }
            }
            
            // Try to find total cost
            if data.totalCost == nil && (lowercased.contains("total") || lowercased.contains("amount")) {
                if let amount = extractDecimal(from: line) {
                    data.totalCost = amount
                }
            }
            
            // Try to find volume (litres)
            if data.amountInLitres == nil && (lowercased.contains("litres") || lowercased.contains("volume") || lowercased.contains("qty")) {
                if let amount = extractDecimal(from: line) {
                    data.amountInLitres = amount
                }
            }
        }
        
        return data
    }
    
    private func extractDecimal(from text: String) -> Double? {
        let pattern = #"\d+[\.,]\d{2}"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            let decimalStr = text[range].replacingOccurrences(of: ",", with: ".")
            return Double(decimalStr)
        }
        return nil
    }
}
