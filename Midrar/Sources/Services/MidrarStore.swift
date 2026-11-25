import Foundation
import SwiftUI

@MainActor
final class MidrarStore: ObservableObject {
    nonisolated static var maxStage: Int { 598 }
    nonisolated static var totalCycleDhikr: Int64 { 15000 }

    @Published var state: AppState
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var leaderboardOnline: Bool = false
    @Published var activeAnnouncement: RemoteAppConfig?
    @Published var showCycleCelebration: Bool = false

    private let stateKey = "midrar_ios_app_state_v1"
    private var saveTask: Task<Void, Never>?

    init() {
        if let data = UserDefaults.standard.data(forKey: stateKey),
           let decoded = try? JSONDecoder().decode(AppState.self, from: data) {
            self.state = decoded
        } else {
            self.state = AppState()
        }
        rollDayIfNeeded()
        HapticsAndAudio.shared.hapticsEnabled = state.settings.hapticsEnabled
        HapticsAndAudio.shared.soundEnabled = state.settings.soundEnabled
        self.leaderboard = SupabaseService.shared.getCachedTop30()
    }

    var isFemale: Bool {
        state.userGender == "female"
    }

    var accentColor: Color {
        state.settings.accentTheme.color(isFemale: isFemale)
    }

    var preferredColorScheme: ColorScheme? {
        switch state.settings.themeMode {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }

    var activeDhikr: DhikrItem {
        allDhikrs.first(where: { $0.id == state.activeDhikrId }) ?? DhikrItem.defaults[0]
    }

    var allDhikrs: [DhikrItem] {
        DhikrItem.defaults + state.customDhikrs
    }

    var currentStage: Int {
        Self.computeStage(totalDhikr: state.totalIstighfar)
    }

    var isWilted: Bool {
        guard state.lastTapTimestamp > 0, currentStage >= 4 else { return false }
        return Date().timeIntervalSince1970 - state.lastTapTimestamp >= 12 * 3600
    }

    var currentFrameName: String {
        if isWilted {
            let w = currentStage <= 150 ? 1 : (currentStage <= 320 ? 2 : 3)
            return "wilted_\(w)"
        }
        return "stage_\(currentStage)"
    }

    nonisolated static func computeStage(totalDhikr: Int64) -> Int {
        let c = Double(max(0, totalDhikr))
        let maxIdx = Double(maxStage - 1)
        let idx: Double
        if c >= Double(totalCycleDhikr) {
            idx = maxIdx
        } else if c <= 100 {
            idx = (c / 100.0) * 64.0
        } else if c <= 500 {
            idx = 64.0 + ((c - 100.0) / 400.0) * 115.0
        } else if c <= 2500 {
            idx = 179.0 + ((c - 500.0) / 2000.0) * 150.0
        } else if c <= 7500 {
            idx = 329.0 + ((c - 2500.0) / 5000.0) * 145.0
        } else {
            idx = 474.0 + ((c - 7500.0) / 7500.0) * (maxIdx - 474.0)
        }
        return max(1, min(maxStage, Int(floor(idx)) + 1))
    }

    func recordDhikrTap() {
        rollDayIfNeeded()
        state.totalIstighfar += 1
        state.todayCount += 1
        state.lastTapTimestamp = Date().timeIntervalSince1970
        if state.totalIstighfar % 3 == 0 {
            state.raindropsCurrency += 1
        }
        let prev = state.dhikrLifetimeCounts[state.activeDhikrId] ?? 0
        state.dhikrLifetimeCounts[state.activeDhikrId] = prev + 1

        let todayKey = Self.todayDateKey()
        state.historyLog[todayKey] = state.todayCount

        if currentStage >= Self.maxStage && !state.hasClaimedCurrentCycleMedal {
            state.hasClaimedCurrentCycleMedal = true
            state.completedCyclesCount += 1
            showCycleCelebration = true
            HapticsAndAudio.shared.milestoneFeedback()
        } else {
            HapticsAndAudio.shared.tapFeedback()
        }
        scheduleSave()
    }

    func isHabitDone(dateKey: String, habitKey: String) -> Bool {
        state.dailyHabitsLog[dateKey]?[habitKey] ?? false
    }

    func toggleHabit(dateKey: String, habitKey: String) {
        var day = state.dailyHabitsLog[dateKey] ?? [:]
        day[habitKey] = !(day[habitKey] ?? false)
        state.dailyHabitsLog[dateKey] = day
        HapticsAndAudio.shared.gentleTick()
        saveImmediate()
    }

    func setHabitDone(dateKey: String, habitKey: String, done: Bool) {
        var day = state.dailyHabitsLog[dateKey] ?? [:]
        day[habitKey] = done
        state.dailyHabitsLog[dateKey] = day
        saveImmediate()
    }

    func countDone(dateKey: String, keys: [String]) -> Int {
        keys.filter { isHabitDone(dateKey: dateKey, habitKey: $0) }.count
    }

    func dailyHabitScore(dateKey: String) -> Int {
        let prayers = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
        let adhkar = ["adhkar_morning", "adhkar_evening", "adhkar_sleep"]
        let sunnah = ["sunnah_fajr", "sunnah_dhuhr_pre", "sunnah_dhuhr_post", "sunnah_maghrib", "sunnah_isha", "qiyam", "witr"]
        var score = 0.0
        score += (Double(countDone(dateKey: dateKey, keys: prayers)) / 5.0) * 50.0
        score += (Double(countDone(dateKey: dateKey, keys: adhkar)) / 3.0) * 10.0
        score += isHabitDone(dateKey: dateKey, habitKey: "quran_daily") ? 10.0 : 0.0
        score += isHabitDone(dateKey: dateKey, habitKey: "duha") ? 10.0 : 0.0
        score += (Double(countDone(dateKey: dateKey, keys: sunnah)) / 7.0) * 10.0
        score += isHabitDone(dateKey: dateKey, habitKey: "fasting") ? 10.0 : 0.0
        return min(100, max(0, Int(score.rounded())))
    }

    func refreshLeaderboardAndConfig() {
        Task {
            let result = await SupabaseService.shared.syncAndFetchTop30(state: state)
            self.leaderboardOnline = result.online
            self.leaderboard = result.entries

            if let cfg = await SupabaseService.shared.checkRemoteConfig(),
               let annId = cfg.announcement_id,
               let title = cfg.announcement_title, !title.isEmpty,
               let body = cfg.announcement_body, !body.isEmpty,
               SupabaseService.shared.shouldShowAnnouncement(id: annId) {
                self.activeAnnouncement = cfg
            }
        }
    }

    func saveImmediate() {
        saveTask?.cancel()
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            self?.saveImmediate()
        }
    }

    private func rollDayIfNeeded() {
        let today = Self.todayDateKey()
        if state.lastActiveDate != today {
            if !state.lastActiveDate.isEmpty {
                state.currentStreak += 1
                state.longestStreak = max(state.longestStreak, state.currentStreak)
            }
            state.lastActiveDate = today
            state.todayCount = state.historyLog[today] ?? 0
        }
    }

    static func todayDateKey() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }
}
