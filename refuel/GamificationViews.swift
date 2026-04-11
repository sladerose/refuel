import SwiftUI

struct StreakIndicator: View {
    @Environment(GamificationManager.self) private var gamificationManager
    
    var body: some View {
        if let profile = gamificationManager.userProfile, profile.streakCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(profile.streakCount)")
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 2)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    StreakIndicator()
        .environment(GamificationManager(modelContainer: try! ModelContainer(for: Schema([UserProfile.self]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])))
}
