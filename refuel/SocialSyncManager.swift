import Foundation
import CloudKit
import Observation

// MARK: - LeaderboardEntry value type (per RESEARCH.md Pattern 6)

struct LeaderboardEntry: Identifiable, Sendable {
    let id: String            // CKRecord.ID.recordName (= UserProfile.id.uuidString)
    let alias: String         // "Scout#XXXX" (D-01)
    let xp: Int               // ranking metric (D-06)
    let rank: String          // rank.rawValue
    let communityImpact: Double
    let contributionCount: Int

    init(from record: CKRecord) {
        id = record.recordID.recordName
        alias = record["alias"] as? String ?? "Scout#????"
        xp = record["xp"] as? Int ?? 0
        rank = record["rank"] as? String ?? "Newcomer"
        communityImpact = record["communityImpact"] as? Double ?? 0
        contributionCount = record["contributionCount"] as? Int ?? 0
    }
}

// MARK: - SocialSyncManager

@Observable
final class SocialSyncManager {

    // MARK: - Constants

    private static let containerID = "iCloud.com.refuel.app"
    private static let recordType = "ScoutLeaderboard"
    private static let udKey = "communityShareEnabled"

    // MARK: - State

    enum SyncState: Equatable {
        case idle
        case syncing
        case error(String)
    }

    var leaderboard: [LeaderboardEntry] = []
    var syncState: SyncState = .idle

    /// Opt-in flag persisted in UserDefaults (per D-07: default off; not synced via CloudKit).
    var isCommunityShareEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.udKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.udKey) }
    }

    // MARK: - Private

    @ObservationIgnored private var pendingSyncTask: Task<Void, Never>?

    private var publicDB: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    // MARK: - Opt-in write (D-07)

    /// Called immediately when the user toggles Community Sharing ON.
    /// Guards against no-iCloud-account silently failing (RESEARCH.md Pitfall 2).
    func enableSharing(for profile: UserProfile, contributionCount: Int) async {
        guard await accountIsAvailable() else {
            syncState = .error("Couldn't connect. Your stats are safe — will retry.")
            return
        }
        syncState = .syncing
        await upsertPublicRecord(for: profile, contributionCount: contributionCount)
    }

    // MARK: - Opt-out delete (D-08)

    /// Called after the user confirms opt-out. Deletes their public CKRecord.
    func disableSharing(for profile: UserProfile) async {
        isCommunityShareEnabled = false
        syncState = .syncing
        let recordID = CKRecord.ID(recordName: profile.id.uuidString)
        do {
            try await publicDB.deleteRecord(withID: recordID)
            syncState = .idle
        } catch {
            print("SocialSyncManager: delete failed: \(error)")
            // Deletion failure is non-fatal — record will expire or be cleaned up.
            syncState = .idle
        }
    }

    // MARK: - Debounced event-triggered sync (D-05)

    /// Coalesces rapid XP events into a single write.
    /// Called by GamificationManager.awardXP when isCommunityShareEnabled.
    func triggerDebouncedSync(profile: UserProfile, contributionCount: Int) {
        pendingSyncTask?.cancel()
        pendingSyncTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await self.upsertPublicRecord(for: profile, contributionCount: contributionCount)
        }
    }

    // MARK: - Leaderboard fetch (D-03, D-06)

    /// Fetches top 100 users globally, sorted by XP descending.
    /// NOTE: Requires a Sortable index on the `xp` field in CloudKit Console
    /// (see RESEARCH.md Pitfall 1 and VALIDATION.md manual check).
    func fetchLeaderboard(limit: Int = 100) async {
        guard await accountIsAvailable() else {
            syncState = .error("iCloud not available.")
            return
        }
        syncState = .syncing
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Self.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "xp", ascending: false)]
        do {
            let (matchResults, _) = try await publicDB.records(matching: query, resultsLimit: limit)
            // Extract values on this task before crossing any actor boundary (Swift 6 Sendability — Pitfall 7)
            let entries = matchResults.compactMap { (_, result) -> LeaderboardEntry? in
                guard let record = try? result.get() else { return nil }
                return LeaderboardEntry(from: record)
            }
            leaderboard = entries
            syncState = .idle
        } catch {
            print("SocialSyncManager: fetch failed: \(error)")
            syncState = .error("Couldn't load leaderboard.")
        }
    }

    // MARK: - Private helpers

    /// Upsert: deterministic CKRecord.ID from profile UUID ensures save() acts as an upsert (Pitfall 3).
    /// CKRecord schema: ScoutLeaderboard with fields alias(String), xp(Int64), rank(String),
    /// communityImpact(Double), contributionCount(Int64), lastSynced(DateTime).
    private func upsertPublicRecord(for profile: UserProfile, contributionCount: Int) async {
        // Deterministic record ID = UserProfile.id.uuidString (RESEARCH.md Pattern 2)
        let recordID = CKRecord.ID(recordName: profile.id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["alias"] = profile.communityAlias as CKRecordValue         // D-01
        record["xp"] = profile.xp as CKRecordValue                        // D-04, D-06
        record["rank"] = profile.rank.rawValue as CKRecordValue            // D-04
        record["communityImpact"] = profile.communityImpact as CKRecordValue // D-04
        record["contributionCount"] = contributionCount as CKRecordValue   // D-04
        record["lastSynced"] = Date() as CKRecordValue
        do {
            try await publicDB.save(record)
            syncState = .idle
        } catch {
            print("SocialSyncManager: upsert failed: \(error)")
            syncState = .error("Couldn't connect. Your stats are safe — will retry.")
        }
    }

    private func accountIsAvailable() async -> Bool {
        let status = try? await CKContainer(identifier: Self.containerID).accountStatus()
        return status == .available
    }
}
