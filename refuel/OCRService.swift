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
        var allObservations = [VNRecognizedTextObservation]()
        let group = DispatchGroup()
        
        for image in images {
            guard let cgImage = image.cgImage else { continue }
            group.enter()
            
            let request = VNRecognizeTextRequest { (request, error) in
                defer { group.leave() }
                if let results = request.results as? [VNRecognizedTextObservation] {
                    allObservations.append(contentsOf: results)
                }
            }
            
            // Optimization for Structured Numerical Data
            request.recognitionLevel = .accurate
            if #available(iOS 16.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
            }
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = false // Crucial: don't let it "fix" prices into words
            request.customWords = ["TOTAL", "LITRES", "DIESEL", "UNLEADED", "PETROL", "PRICE", "AMOUNT", "FUEL", "91", "93", "95", "98"]
            
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
            let data = self.parseObservations(allObservations, stations: stations)
            completion(data)
        }
    }
    
    private func parseObservations(_ observations: [VNRecognizedTextObservation], stations: [Station]) -> ScannedReceiptData {
        // Group observations by line using their vertical position (minY)
        let lines = groupObservationsByLine(observations)
        let allLines = lines.map { $0.joined(separator: " ") }
        
        return parseText(allLines, stations: stations)
    }
    
    internal func parseText(_ allLines: [String], stations: [Station]) -> ScannedReceiptData {
        var data = ScannedReceiptData()
        let allText = allLines.joined(separator: "\n").lowercased()
        
        // 1. Station Name
        for station in stations {
            if allText.contains(station.name.lowercased()) {
                data.stationName = station.name
                break
            }
        }
        
        // 2. Date
        data.date = extractDate(from: allText)
        
        // 3. Smart Grade & Numerical Extraction using line grouping
        for lineText in allLines {
            let lowerLine = lineText.lowercased()
            
            // Extract Grade
            if data.grade == nil {
                if lowerLine.contains("91") || lowerLine.contains("unleaded") || lowerLine.contains("ulp") { data.grade = "91" }
                else if lowerLine.contains("95") || lowerLine.contains("premium") { data.grade = "95" }
                else if lowerLine.contains("diesel") { data.grade = "Diesel" }
            }
            
            // Extract Volume (look for L or Litres)
            if data.amountInLitres == nil && (lowerLine.contains("litres") || lowerLine.contains("vol") || lowerLine.contains("qty")) {
                if let amount = extractDecimal(from: lineText) {
                    data.amountInLitres = amount
                }
            }
            
            // Extract Price Per Litre
            if data.pricePerLitre == nil && (lowerLine.contains("price") || lowerLine.contains("$/l") || lowerLine.contains("@")) {
                if let amount = extractDecimal(from: lineText) {
                    data.pricePerLitre = amount
                }
            }
            
            // Extract Total
            if data.totalCost == nil && (lowerLine.contains("total") || lowerLine.contains("amt") || lowerLine.contains("paid")) {
                if let amount = extractDecimal(from: lineText) {
                    data.totalCost = amount
                }
            }
        }
        
        // Fallback calculation
        if let total = data.totalCost, let volume = data.amountInLitres, data.pricePerLitre == nil, volume > 0 {
            data.pricePerLitre = (total / volume * 100).rounded() / 100
        }
        
        return data
    }
    
    private func groupObservationsByLine(_ observations: [VNRecognizedTextObservation]) -> [[String]] {
        // Sort by vertical position (top to bottom)
        let sorted = observations.sorted { $0.boundingBox.minY > $1.boundingBox.minY }
        
        var lines = [[VNRecognizedTextObservation]]()
        for observation in sorted {
            if let lastLine = lines.last,
               let lastObservation = lastLine.last,
               abs(lastObservation.boundingBox.midY - observation.boundingBox.midY) < 0.01 {
                // Same line (small vertical difference)
                var updatedLine = lastLine
                updatedLine.append(observation)
                lines[lines.count - 1] = updatedLine
            } else {
                // New line
                lines.append([observation])
            }
        }
        
        // Within each line, sort by horizontal position (left to right)
        return lines.map { line in
            line.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
                .compactMap { $0.topCandidates(1).first?.string }
        }
    }
    
    internal func parsePriceBoard(_ lines: [String]) -> [String: Double] {
        var results = [String: Double]()
        let grades = ["91", "93", "95", "98", "diesel", "ulp", "pwr", "premium"]
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            
            for grade in grades {
                if lowercased.contains(grade) {
                    let normalizedGrade = mapGrade(grade)
                    
                    // Look for price in same line first
                    if let price = extractDecimal(from: line) {
                        results[normalizedGrade] = price
                    } else {
                        // Look at the next line (often prices are vertically aligned below or next to grade)
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
    
    private func mapGrade(_ raw: String) -> String {
        switch raw {
        case "ulp", "91": return "91"
        case "95", "premium", "pwr": return "95"
        case "diesel": return "Diesel"
        default: return raw.uppercased()
        }
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
        // Look for patterns like 12.34 or 12,34
        let pattern = #"\d+[\.,]\d{2}"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            let decimalStr = text[range].replacingOccurrences(of: ",", with: ".")
            return Double(decimalStr)
        }
        return nil
    }
}
