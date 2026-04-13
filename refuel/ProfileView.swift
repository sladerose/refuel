import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(GamificationManager.self) private var gamificationManager
    @State private var animatedGlobalImpact: Double = 0
    
    var body: some View {
        NavigationStack {
            List {
                if let profile = gamificationManager.userProfile {
                    Section {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: rankIcon(for: profile.rank))
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.rank.rawValue)
                                    .font(.headline)
                                
                                Text("\(profile.xp) XP • Level \(profile.rank.level)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        VStack(spacing: 8) {
                            let nextThreshold = profile.rank.nextRankThreshold ?? profile.xp
                            let progress = Double(profile.xp) / Double(nextThreshold)
                            
                            ProgressView(value: progress)
                                .tint(.orange)
                            
                            HStack {
                                if let next = profile.rank.nextRankThreshold {
                                    Text("\(next - profile.xp) XP to next level")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Maximum Rank Achieved")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section("Your Stats") {
                        LabeledContent {
                            Text("\(profile.streakCount) Days")
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        } label: {
                            Label("Current Streak", systemImage: "flame.fill")
                        }
                        
                        LabeledContent {
                            Text("\(gamificationManager.monthlyLuckyDrawEntries)")
                                .fontWeight(.semibold)
                                .foregroundStyle(.purple)
                        } label: {
                            Label("Lucky Draws", systemImage: "ticket.fill")
                        }
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Community Impact", systemImage: "person.3.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Global Network Savings")
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
                            
                            Text("You've helped others save R\(String(format: "%.0f", profile.communityImpact))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)

                    NavigationLink(destination: LeaderboardView()) {
                        Label("Global Leaderboard", systemImage: "chart.bar.fill")
                    }
                    } header: {
                        Text("Scout Network")
                    }

                    Section("Settings") {
                        HStack {
                            Label("iCloud Sync", systemImage: "icloud.and.arrow.up.fill")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Synced")
                                    .foregroundColor(.secondary)
                            }
                        }
                        CommunitySyncSettingsRow()
                    }
                    
                    Section {
                        Button {
                            shareImpact()
                        } label: {
                            Label("Share My Achievement", systemImage: "square.and.arrow.up")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.orange)
                    }
                    
                } else {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Loading Profile...")
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
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
        renderer.scale = 3.0
        
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

// MARK: - CommunitySyncSettingsRow (UI-SPEC Component Inventory)

struct CommunitySyncSettingsRow: View {
    @Environment(SocialSyncManager.self) private var socialSyncManager
    @Environment(GamificationManager.self) private var gamificationManager

    @State private var showOptOutDialog = false
    @State private var inlineMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Community Sharing", systemImage: "globe")

                Spacer()

                Toggle("", isOn: Binding(
                    get: { socialSyncManager.isCommunityShareEnabled },
                    set: { newValue in
                        if newValue {
                            socialSyncManager.isCommunityShareEnabled = true
                            Task { await handleToggleOn() }
                        } else {
                            showOptOutDialog = true
                        }
                    }
                ))
                .labelsHidden()
                .tint(.orange)
            }
            .frame(minHeight: 44)

            Text("Share your alias and XP with the global Fuel Scout community.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let message = inlineMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(
                        message.hasPrefix("Couldn't") ? Color.red : Color.secondary
                    )
                    .transition(.opacity)
            }

            if case .syncing = socialSyncManager.syncState, socialSyncManager.isCommunityShareEnabled {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Syncing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: inlineMessage)
        .animation(.easeInOut(duration: 0.2), value: socialSyncManager.syncState == .idle)
        .confirmationDialog(
            "Stop sharing your stats?",
            isPresented: $showOptOutDialog,
            titleVisibility: .visible
        ) {
            Button("Stop Sharing", role: .destructive) {
                Task { await handleToggleOff() }
            }
            Button("Keep Sharing", role: .cancel) {}
        } message: {
            Text("Your alias and XP will be removed from the global leaderboard.")
        }
        .onChange(of: socialSyncManager.syncState) { _, newState in
            if case .error(let msg) = newState {
                socialSyncManager.isCommunityShareEnabled = false
                withAnimation { inlineMessage = msg }
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation { inlineMessage = nil }
                }
            }
        }
    }

    @MainActor
    private func handleToggleOn() async {
        guard let profile = gamificationManager.userProfile else { return }
        let contributions = gamificationManager.totalContributionCount()
        await socialSyncManager.enableSharing(for: profile, contributionCount: contributions)
        if case .error = socialSyncManager.syncState {
            // onChange handler sets inlineMessage from error
        } else {
            withAnimation { inlineMessage = "Sharing enabled" }
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation { inlineMessage = nil }
            }
        }
    }

    @MainActor
    private func handleToggleOff() async {
        guard let profile = gamificationManager.userProfile else { return }
        await socialSyncManager.disableSharing(for: profile)
        withAnimation { inlineMessage = "Sharing disabled" }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { inlineMessage = nil }
        }
    }
}

extension UserProfile.Rank {
    var level: Int {
        switch self {
        case .newcomer: return 1
        case .activeMember: return 2
        case .reliableContributor: return 3
        case .expertScout: return 4
        case .fuelLegend: return 5
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([Station.self, FuelPrice.self, RefuelEvent.self, UserProfile.self]), configurations: [config])
    return ProfileView()
        .environment(GamificationManager(modelContainer: container))
}
