import SwiftUI
import SwiftData
import CloudKit

// MARK: - LeaderboardView

struct LeaderboardView: View {
    @Environment(SocialSyncManager.self) private var socialSyncManager
    @Environment(GamificationManager.self) private var gamificationManager

    /// Track whether the "You" row is currently visible in the scroll view.
    @State private var isOwnRowVisible = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                content
                // Sticky footer: appears when own row scrolls off-screen (D-02)
                if !isOwnRowVisible, let ownEntry = ownLeaderboardEntry {
                    stickyFooter(for: ownEntry)
                }
            }
            .navigationTitle("Global Leaderboard")   // UI-SPEC Copywriting
        }
    }

    // MARK: - Main content router

    @ViewBuilder
    private var content: some View {
        switch socialSyncManager.syncState {
        case .syncing where socialSyncManager.leaderboard.isEmpty:
            // Initial load state (UI-SPEC: full-screen ProgressView)
            ProgressView("Loading leaderboard...")           // UI-SPEC Copywriting
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let message):
            errorView(message: message)

        default:
            leaderboardList
        }
    }

    // MARK: - Leaderboard list

    private var leaderboardList: some View {
        List {
            // Opt-in prompt banner when sharing is OFF (UI-SPEC Interaction Contract)
            if !socialSyncManager.isCommunityShareEnabled {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(.orange)
                        Text("Join the leaderboard — enable Community Sharing in Profile > Settings")   // UI-SPEC Copywriting
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if socialSyncManager.leaderboard.isEmpty && socialSyncManager.syncState == .idle {
                // Empty state (UI-SPEC Empty Leaderboard State)
                Section {
                    emptyStateView
                }
            } else {
                // Leaderboard rows (UI-SPEC section header "Top Fuel Scouts")
                Section("Top Fuel Scouts") {
                    ForEach(Array(socialSyncManager.leaderboard.enumerated()), id: \.element.id) { index, entry in
                        let isOwn = entry.alias == (gamificationManager.userProfile?.communityAlias ?? "")
                        LeaderboardRowView(position: index + 1, entry: entry, isOwn: isOwn)
                            .onAppear {
                                if isOwn { isOwnRowVisible = true }
                            }
                            .onDisappear {
                                if isOwn { isOwnRowVisible = false }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            // Pull-to-refresh (UI-SPEC Interaction Contract)
            await socialSyncManager.fetchLeaderboard()
        }
        .task {
            // Fetch on view appear
            if socialSyncManager.leaderboard.isEmpty {
                await socialSyncManager.fetchLeaderboard()
            }
        }
    }

    // MARK: - Empty state view (UI-SPEC Empty Leaderboard State)

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")       // UI-SPEC: SF Symbol
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No scouts on the board yet")        // UI-SPEC Copywriting
                .font(.headline)

            Text("Be the first — enable Community Sharing in Profile > Settings.")  // UI-SPEC Copywriting
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 48)                      // UI-SPEC 2xl = 48pt for empty state
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error view

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Sticky footer (D-02, UI-SPEC Interaction Contract)

    private func stickyFooter(for entry: LeaderboardEntry) -> some View {
        let position = (socialSyncManager.leaderboard.firstIndex(where: { $0.id == entry.id }) ?? 0) + 1
        return HStack {
            Text("Your position: #\(position) • \(entry.xp) XP")  // UI-SPEC Copywriting
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.orange.opacity(0.4)),
            alignment: .top
        )
    }

    // MARK: - Helpers

    private var ownLeaderboardEntry: LeaderboardEntry? {
        guard let alias = gamificationManager.userProfile?.communityAlias else { return nil }
        return socialSyncManager.leaderboard.first(where: { $0.alias == alias })
    }
}

// MARK: - LeaderboardRowView (UI-SPEC Component Inventory)

struct LeaderboardRowView: View {
    let position: Int
    let entry: LeaderboardEntry
    let isOwn: Bool

    var body: some View {
        HStack(spacing: 8) {                          // UI-SPEC sm = 8pt intra-row spacing
            // Position number
            Text("#\(position)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(isOwn ? .orange : .primary)
                .frame(minWidth: 36, alignment: .leading)

            // Rank badge circle (UI-SPEC: rank badge tints, .rounded variant)
            ZStack {
                Circle()
                    .fill(rankBadgeColor(for: entry.rank))
                    .frame(width: 32, height: 32)
                Image(systemName: rankIcon(for: entry.rank))
                    .font(.caption)
                    .foregroundStyle(.white)
            }

            // Alias + rank label
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {                  // UI-SPEC xs = 4pt icon-to-label gap
                    Text(entry.alias)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isOwn ? .orange : .primary)

                    // "You" pill (D-02, UI-SPEC)
                    if isOwn {
                        Text("You")                   // UI-SPEC Copywriting
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                            .fontDesign(.rounded)     // UI-SPEC .rounded variant for pill
                    }
                }

                Text(entry.rank)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // XP value (UI-SPEC .monospaced to prevent layout shift)
            Text("\(entry.xp) XP")
                .font(.headline)
                .fontWeight(.regular)
                .monospaced()
                .foregroundStyle(isOwn ? .orange : .primary)
        }
        .padding(.vertical, 4)                        // UI-SPEC sm = 8pt vertical stat gap
        .listRowBackground(
            isOwn
                ? Color.orange.opacity(0.12).background(.ultraThinMaterial)  // UI-SPEC "You" row
                : Color.clear.background(.ultraThinMaterial)
        )
    }

    // MARK: - Rank badge color (UI-SPEC: orange -> purple gradient per existing ProfileView)

    private func rankBadgeColor(for rank: String) -> Color {
        switch rank {
        case "Newcomer": return .orange
        case "Active Member": return Color(red: 0.9, green: 0.5, blue: 0.1)
        case "Reliable Contributor": return Color(red: 0.7, green: 0.3, blue: 0.6)
        case "Expert Scout": return Color(red: 0.5, green: 0.2, blue: 0.8)
        case "Fuel Legend": return .purple
        default: return .orange
        }
    }

    private func rankIcon(for rank: String) -> String {
        switch rank {
        case "Newcomer": return "person.fill"
        case "Active Member": return "person.text.rectangle.fill"
        case "Reliable Contributor": return "shield.fill"
        case "Expert Scout": return "sparkles"
        case "Fuel Legend": return "crown.fill"
        default: return "person.fill"
        }
    }
}

// MARK: - Preview helper

extension LeaderboardEntry {
    static func preview(id: String, alias: String, xp: Int, rank: String) -> LeaderboardEntry {
        let record = CKRecord(recordType: "ScoutLeaderboard", recordID: CKRecord.ID(recordName: id))
        record["alias"] = alias as CKRecordValue
        record["xp"] = xp as CKRecordValue
        record["rank"] = rank as CKRecordValue
        record["communityImpact"] = 0.0 as CKRecordValue
        record["contributionCount"] = 0 as CKRecordValue
        return LeaderboardEntry(from: record)
    }
}

// MARK: - Preview

#Preview {
    let syncManager = SocialSyncManager()
    let sampleEntries = [
        LeaderboardEntry.preview(id: "user-001", alias: "Scout#A1B2", xp: 4200, rank: "Expert Scout"),
        LeaderboardEntry.preview(id: "user-002", alias: "Scout#F3E4", xp: 3100, rank: "Reliable Contributor"),
        LeaderboardEntry.preview(id: "user-003", alias: "Scout#C5D6", xp: 2800, rank: "Reliable Contributor"),
    ]
    syncManager.leaderboard = sampleEntries

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([Station.self, FuelPrice.self, RefuelEvent.self, UserProfile.self]), configurations: [config])
    let gManager = GamificationManager(modelContainer: container)

    return LeaderboardView()
        .environment(syncManager)
        .environment(gManager)
}
