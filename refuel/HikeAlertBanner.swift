//
//  HikeAlertBanner.swift
//  refuel
//
//  Created by slade on 2026/04/12.
//

import SwiftUI

struct HikeAlertBanner: View {
    let proactiveService: ProactiveService
    
    var body: some View {
        HStack {
            Image(systemName: "fuelpump.fill")
                .foregroundColor(.white)
            VStack(alignment: .leading) {
                Text("Fuel Hike Imminent!")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("Prices rise in \(timeRemaining)")
                    .font(.caption)
            }
            .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.red)
    }
    
    var timeRemaining: String {
        let diff = proactiveService.nextFirstWednesday().timeIntervalSinceNow
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
