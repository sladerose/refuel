import SwiftUI

struct AchievementCardView: View {
    let rank: UserProfile.Rank
    let savings: Double
    let streak: Int
    
    var body: some View {
        VStack(spacing: 24) {
            // Branded Header
            HStack {
                Image(systemName: "fuelpump.fill")
                    .font(.largeTitle)
                Text("REFUEL")
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.black)
            }
            .foregroundColor(.orange)
            
            // Achievement Message
            VStack(spacing: 8) {
                Text("I saved")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text(String(format: "R%.2f", savings))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("this month with Refuel!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Rank and Streak
            HStack(spacing: 40) {
                VStack {
                    Image(systemName: rankIcon)
                        .font(.title)
                        .foregroundColor(.orange)
                    Text(rank.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("\(streak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("DAY STREAK")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            
            Spacer()
            
            // Call to Action
            Text("Join the Fuel Scouts")
                .font(.footnote)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .padding(40)
        .frame(width: 400, height: 400)
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .shadow(radius: 20)
    }
    
    private var rankIcon: String {
        switch rank {
        case .newcomer: return "person.fill"
        case .activeMember: return "person.text.rectangle.fill"
        case .reliableContributor: return "shield.fill"
        case .expertScout: return "sparkles"
        case .fuelLegend: return "crown.fill"
        }
    }
}

#Preview {
    AchievementCardView(rank: .expertScout, savings: 124.50, streak: 12)
        .previewLayout(.sizeThatFits)
}
