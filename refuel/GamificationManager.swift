import Foundation
import SwiftData
import Observation

@Observable
final class GamificationManager {
    private var modelContext: ModelContext
    private(set) var userProfile: UserProfile?
    var socialSyncManager: SocialSyncManager?
    
    init(modelContainer: ModelContainer) {
        self.modelContext = ModelContext(modelContainer)
        fetchOrCreateProfile()
    }
    
    @MainActor
    private func fetchOrCreateProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let profile = profiles.first {
                self.userProfile = profile
            } else {
                let newProfile = UserProfile()
                modelContext.insert(newProfile)
                try modelContext.save()
                self.userProfile = newProfile
            }
        } catch {
            print("Failed to fetch/create UserProfile: \(error)")
        }
    }
    
    @MainActor
    func awardXP(amount: Int, stationName: String? = nil, type: String = "verify") {
        guard let profile = userProfile else { return }
        
        profile.xp += amount
        updateStreak()
        
        if let name = stationName {
            createLuckyDrawEntry(type: type, stationName: name)
        }
        
        try? modelContext.save()

        // D-05: Trigger debounced community sync on significant XP events
        if let sm = socialSyncManager, sm.isCommunityShareEnabled, let profile = userProfile {
            let contributions = totalContributionCount()
            sm.triggerDebouncedSync(profile: profile, contributionCount: contributions)
        }
    }

    @MainActor
    func totalContributionCount() -> Int {
        let descriptor = FetchDescriptor<LuckyDrawEntry>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    @MainActor
    private func createLuckyDrawEntry(type: String, stationName: String) {
        let entry = LuckyDrawEntry(stationName: stationName, contributionType: type)
        modelContext.insert(entry)
    }
    
    @MainActor
    var monthlyLuckyDrawEntries: Int {
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let descriptor = FetchDescriptor<LuckyDrawEntry>(
            predicate: #Predicate { $0.date >= startOfMonth }
        )
        
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    @MainActor
    var globalImpactTotal: Double {
        // Mocked by locally aggregating and multiplying
        let descriptor = FetchDescriptor<LuckyDrawEntry>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return 1420560.0 + Double(count * 15) // Baseline + new contributions
    }
    
    @MainActor
    func addCommunityImpact(savings: Double) {
        guard let profile = userProfile else { return }
        profile.communityImpact += savings
        try? modelContext.save()
    }
    
    @MainActor
    private func updateStreak() {
        guard let profile = userProfile else { return }
        let now = Date()
        
        guard let lastDate = profile.lastContributionDate else {
            // First ever contribution
            profile.streakCount = 1
            profile.lastContributionDate = now
            return
        }
        
        let calendar = Calendar.current
        
        // If it's already the same day, don't increment streak but update time
        if calendar.isDate(now, inSameDayAs: lastDate) {
            profile.lastContributionDate = now
            return
        }
        
        // Check if within 10 days (streak grace period)
        let diff = calendar.dateComponents([.day], from: lastDate, to: now).day ?? 0
        
        if diff <= 10 {
            profile.streakCount += 1
        } else {
            // Streak broken
            profile.streakCount = 1
        }
        
        profile.lastContributionDate = now
    }
}
