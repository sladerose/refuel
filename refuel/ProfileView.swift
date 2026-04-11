import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(GamificationManager.self) private var gamificationManager
    @State private var animatedGlobalImpact: Double = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let profile = gamificationManager.userProfile {
                        // Rank Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: rankIcon(for: profile.rank))
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            Text(profile.rank.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 6) {
                                let nextThreshold = profile.rank.nextRankThreshold ?? profile.xp
                                let progress = Double(profile.xp) / Double(nextThreshold)
                                
                                ProgressView(value: progress)
                                    .tint(.orange)
                                
                                HStack {
                                    Text("\(profile.xp) XP")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if let next = profile.rank.nextRankThreshold {
                                        Text("Next level at \(next) XP")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Max Level Reached")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                        .padding(.vertical)
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(title: "Streak", value: "\(profile.streakCount) Days", icon: "flame.fill", color: .orange)
                            StatCard(title: "Lottery Entries", value: "\(gamificationManager.monthlyLotteryEntries)", icon: "ticket.fill", color: .purple)
                        }
                        .padding(.horizontal)
                        
                        // Community Dashboard
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Fuel Scout Network")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Global Community Savings")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "R%.0f", animatedGlobalImpact))
                                        .font(.title)
                                        .fontWeight(.black)
                                        .foregroundColor(.green)
                                        .contentTransition(.numericText())
                                }
                                Spacer()
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }
                            
                            Text("Your personal impact: \(String(format: "R%.0f", profile.communityImpact)) saved for others.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Share Button
                        Button(action: shareImpact) {
                            Label("Share My Impact", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                    } else {
                        ProgressView("Loading Profile...")
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Profile")
            .onAppear {
                withAnimation(.interpolatingSpring(stiffness: 10, damping: 5).delay(0.5)) {
                    animatedGlobalImpact = gamificationManager.globalImpactTotal
                }
            }
        }
    }
    
    @MainActor
    private func shareImpact() {
        guard let profile = gamificationManager.userProfile else { return }
        
        let card = AchievementCardView(
            rank: profile.rank,
            savings: profile.communityImpact,
            streak: profile.streakCount
        )
        
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // High quality
        
        if let uiImage = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [uiImage, "I'm saving money on fuel with Refuel! Join the Fuel Scouts."], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    private func rankIcon(for rank: UserProfile.Rank) -> String {
        switch rank {
        case .newcomer: return "person.fill"
        case .activeMember: return "person.text.rectangle.fill"
        case .reliableContributor: return "shield.fill"
        case .expertScout: return "sparkles"
        case .fuelLegend: return "crown.fill"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([Station.self, FuelPrice.self, RefuelEvent.self, UserProfile.self]), configurations: [config])
    return ProfileView()
        .environment(GamificationManager(modelContainer: container))
}
