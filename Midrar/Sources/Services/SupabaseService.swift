import Foundation

final class SupabaseService {
    static let shared = SupabaseService()
    static let projectURL = "https://gcpthkkccbmmqmgwarja.supabase.co"
    static let publishableKey = "sb_publishable_qUUItu1qGnpOGqKNg9xhdA_z3_KXMYw"
    static let defaultDownloadURL = "https://github.com/khaleedqw999-beep/midrar-app/releases/download/3.6/Midrar.apk"

    private let cacheKey = "midrar_ios_cached_top30_v1"
    private let lastAnnKey = "midrar_ios_last_ann_id"
    private let cachedUrlKey = "midrar_ios_cached_download_url"

    private init() {}

    func getCachedTop30() -> [LeaderboardEntry] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    func saveCachedTop30(_ entries: [LeaderboardEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    func getCachedDownloadURL() -> String {
        let saved = UserDefaults.standard.string(forKey: cachedUrlKey) ?? ""
        return saved.isEmpty ? Self.defaultDownloadURL : saved
    }

    func syncAndFetchTop30(state: AppState) async -> (online: Bool, entries: [LeaderboardEntry]) {
        let localSelf = makeSelfEntry(state: state)
        do {
            try await upsertSelf(entry: localSelf)
            let remote = try await fetchTop30Remote()
            let merged = mergeAndRank(base: remote, localSelf: localSelf)
            saveCachedTop30(merged)
            return (true, merged)
        } catch {
            let offline = mergeAndRank(base: getCachedTop30(), localSelf: localSelf)
            saveCachedTop30(offline)
            return (false, offline)
        }
    }

    func checkRemoteConfig() async -> RemoteAppConfig? {
        guard let url = URL(string: "\(Self.projectURL)/rest/v1/app_config?select=*&id=eq.1&limit=1") else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 6
        req.setValue(Self.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            let rows = try JSONDecoder().decode([RemoteAppConfig].self, from: data)
            if let cfg = rows.first {
                if let u = cfg.update_url, u.hasPrefix("http") {
                    UserDefaults.standard.set(u, forKey: cachedUrlKey)
                }
                return cfg
            }
        } catch {}
        return nil
    }

    func shouldShowAnnouncement(id: Int) -> Bool {
        let last = UserDefaults.standard.integer(forKey: lastAnnKey)
        if id > last {
            UserDefaults.standard.set(id, forKey: lastAnnKey)
            return true
        }
        return false
    }

    private func upsertSelf(entry: LeaderboardEntry) async throws {
        guard let url = URL(string: "\(Self.projectURL)/rest/v1/leaderboard?on_conflict=user_id") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 8
        req.setValue(Self.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(entry)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func fetchTop30Remote() async throws -> [LeaderboardEntry] {
        guard let url = URL(string: "\(Self.projectURL)/rest/v1/leaderboard?select=*&order=total_istighfar.desc&limit=30") else {
            return []
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 8
        req.setValue(Self.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
    }

    private func makeSelfEntry(state: AppState) -> LeaderboardEntry {
        let rawName = state.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = rawName.isEmpty ? "ذاكر في مدرار" : rawName
        let medal = state.completedCyclesCount > 0 ? " 🏅\(state.completedCyclesCount)" : ""
        let stage = MidrarStore.computeStage(totalDhikr: state.totalIstighfar)
        return LeaderboardEntry(
            user_id: state.userId,
            display_name: baseName + medal,
            gender: state.userGender,
            total_istighfar: state.totalIstighfar,
            current_streak: state.currentStreak,
            oasis_stage: stage,
            updated_at: nil
        )
    }

    private func mergeAndRank(base: [LeaderboardEntry], localSelf: LeaderboardEntry) -> [LeaderboardEntry] {
        var list = base.filter { $0.user_id != localSelf.user_id }
        list.append(localSelf)
        list.sort { $0.total_istighfar > $1.total_istighfar }
        return Array(list.prefix(30))
    }
}
