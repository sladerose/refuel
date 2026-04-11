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
    
    internal func parseText(_ lines: [String], stations: [Station]) -> ScannedReceiptData {
        var data = ScannedReceiptData()
        
        let allText = lines.joined(separator: "\n").lowercased()
        
        // 1. Station Name (Fuzzy/Exact check)
        for station in stations {
            if allText.contains(station.name.lowercased()) {
                data.stationName = station.name
                break
            }
        }
        
        // 2. Date
        data.date = extractDate(from: allText)
        
        // 3. Grade
        if allText.contains("91") || allText.contains("unleaded") || allText.contains("regular") {
            data.grade = "91"
        } else if allText.contains("95") || allText.contains("premium") {
            data.grade = "95"
        } else if allText.contains("diesel") {
            data.grade = "Diesel"
        }
        
        // 4. Numeric Values (Loop over lines for precision)
        for line in lines {
            let lowercased = line.lowercased()
            
            // Volume (Litres)
            if data.amountInLitres == nil && (lowercased.contains("litres") || lowercased.contains("volume") || lowercased.contains("qty") || lowercased.contains(" q ")) {
                if let amount = extractDecimal(from: line) {
                    data.amountInLitres = amount
                }
            }
            
            // Total Cost
            if data.totalCost == nil && (lowercased.contains("total") || lowercased.contains("amount") || lowercased.contains("paid")) {
                if let amount = extractDecimal(from: line) {
                    data.totalCost = amount
                }
            }
            
            // Price Per Litre
            if data.pricePerLitre == nil && (lowercased.contains("price") || lowercased.contains("$/l")) {
                if let amount = extractDecimal(from: line) {
                    data.pricePerLitre = amount
                }
            }
        }
        
        // Final fallback: If we have Total and Volume but no Price, calculate it
        if let total = data.totalCost, let volume = data.amountInLitres, data.pricePerLitre == nil, volume > 0 {
            data.pricePerLitre = (total / volume * 100).rounded() / 100
        }
        
        return data
    }
    
    private func extractDate(from text: String) -> Date? {
        let patterns = [
            #"(\d{4})[-/](\d{2})[-/](\d{2})"#, // YYYY-MM-DD
            #"(\d{2})[-/](\d{2})[-/](\d{4})"#, // DD-MM-YYYY
            #"(\d{2})[-/](\d{2})[-/](\d{2})"#  // DD-MM-YY
        ]
        
        let formatter = DateFormatter()
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let dateStr = String(text[range])
                
                let formats = ["yyyy-MM-dd", "yyyy/MM/dd", "dd-MM-yyyy", "dd/MM/dd/yyyy", "dd-MM-yy", "dd/MM/yy"]
                for format in formats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
            }
        }
        return nil
    }
    
    internal func extractDecimal(from text: String) -> Double? {
        let pattern = #"\d+[\.,]\d{2}"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            let decimalStr = text[range].replacingOccurrences(of: ",", with: ".")
            return Double(decimalStr)
        }
        return nil
    }
    
    func parsePriceBoard(_ lines: [String]) -> [String: Double] {
        var results = [String: Double]()
        let grades = ["91", "93", "95", "98", "diesel", "ulp", "lrp"]
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            
            for grade in grades {
                if lowercased.contains(grade) {
                    let normalizedGrade = grade.uppercased()
                    
                    // Try to find a price in the current line
                    if let price = extractDecimal(from: line) {
                        results[normalizedGrade] = price
                    } else {
                        // Look at the next few lines for a price
                        for nextIndex in (index + 1)..<min(index + 3, lines.count) {
                            if let price = extractDecimal(from: lines[nextIndex]) {
                                results[normalizedGrade] = price
                                break
                            }
                        }
                    }
                }
            }
        }
        
        return results
    }
}
