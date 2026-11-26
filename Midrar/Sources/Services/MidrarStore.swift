import Foundation
import SwiftUI

@MainActor
final class MidrarStore: ObservableObject {
    nonisolated static let maxStage = 1192
    nonisolated static let cycleTarget = 100_000
    nonisolated static let currentSeasonVersion = 2
    private static let storageKey = "midrar_ios_app_state_v1"

    @Published var state: AppState
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var leaderboardOnline: Bool = false
    @Published var activeAnnouncement: RemoteAppConfig?
    @Published var showCycleCelebration: Bool = false
    @Published var showMosqueChapterCelebration: Bool = false
    @Published var mindfulWarningMessage: String?

    private var saveTask: Task<Void, Never>?
    private var lastTapDate: Date = .distantPast
    private var rapidTapCounter: Int = 0
    private var spamCooldownUntil: Date = .distantPast
    private var recentIntervals: [TimeInterval] = []
    private var minuteWindowStart: Date = Date()
    private var tapsInCurrentMinute: Int = 0

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(AppState.self, from: data) {
            self.state = decoded
        } else {
            self.state = AppState()
        }
        // Season 2 fair 14,000 cap for > 15,000 (preserves everyone else's score)
        if state.seasonVersion < Self.currentSeasonVersion {
            if state.totalIstighfar > 15_000 {
                state.totalIstighfar = 14_000
                state.hasClaimedCurrentCycleMedal = false
                state.hasUnlockedMosqueChapter = false
            }
            state.seasonVersion = Self.currentSeasonVersion
            saveImmediate()
        }
        rollDayIfNeeded()
        HapticsAndAudio.shared.hapticsEnabled = state.settings.hapticsEnabled
        HapticsAndAudio.shared.soundEnabled = state.settings.soundEnabled
        QuranRepository.shared.preloadInBackground()
    }

    var isFemale: Bool { state.userGender == "female" }

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

    var allDhikrs: [DhikrItem] {
        DhikrItem.defaults + state.customDhikrs
    }

    var activeDhikr: DhikrItem {
        allDhikrs.first(where: { $0.id == state.activeDhikrId }) ?? DhikrItem.defaults[0]
    }

    var isWilted: Bool {
        guard state.lastTapTimestamp > 0 else { return false }
        let hours = (Date().timeIntervalSince1970 - state.lastTapTimestamp) / 3600.0
        return hours >= 18.0
    }

    var currentStage: Int {
        Self.computeStage(totalDhikr: state.totalIstighfar)
    }

    var currentFrameName: String {
        if isWilted {
            let hours = (Date().timeIntervalSince1970 - state.lastTapTimestamp) / 3600.0
            if hours >= 48 { return "wilted_3" }
            if hours >= 30 { return "wilted_2" }
            return "wilted_1"
        }
        return "stage_\(currentStage)"
    }

    var dailyGoalProgress: Double {
        min(1.0, Double(state.todayCount) / Double(max(1, state.dailyGoal)))
    }

    var cycleProgress: Double {
        let inCycle = Double(state.totalIstighfar % Int64(Self.cycleTarget))
        if state.totalIstighfar > 0 && inCycle == 0 { return 1.0 }
        return min(1.0, inCycle / Double(Self.cycleTarget))
    }

    nonisolated static func computeStage(totalDhikr: Int64) -> Int {
        let c = Double(totalDhikr % Int64(cycleTarget))
        if totalDhikr > 0 && c == 0 { return maxStage }
        let idx: Double
        if c <= 100 {
            idx = (c / 100.0) * 64.0
        } else if c <= 500 {
            idx = 64.0 + ((c - 100.0) / 400.0) * 115.0
        } else if c <= 2500 {
            idx = 179.0 + ((c - 500.0) / 2000.0) * 150.0
        } else if c <= 7500 {
            idx = 329.0 + ((c - 2500.0) / 5000.0) * 145.0
        } else if c <= 15000 {
            idx = 474.0 + ((c - 7500.0) / 7500.0) * 123.0
        } else if c <= 35000 {
            idx = 598.0 + ((c - 15000.0) / 20000.0) * 149.0
        } else if c <= 60000 {
            idx = 747.0 + ((c - 35000.0) / 25000.0) * 150.0
        } else if c <= 85000 {
            idx = 897.0 + ((c - 60000.0) / 25000.0) * 150.0
        } else {
            idx = 1047.0 + ((c - 85000.0) / 15000.0) * Double(maxStage - 1 - 1047)
        }
        return max(1, min(maxStage, Int(idx.rounded(.down)) + 1))
    }

    /// Returns true if tap passed the 400ms mindful anti-spam & auto-clicker guard
    @discardableResult
    func recordDhikrTap() -> Bool {
        let now = Date()
        if now < spamCooldownUntil {
            mindfulWarningMessage = "تمهّل قليلاً.. الذكر بالقلب واللسان وليس بسرعة الضغط 🌿"
            return false
        }

        let interval = now.timeIntervalSince(lastTapDate)
        if lastTapDate != .distantPast && interval < 0.40 {
            rapidTapCounter += 1
            if rapidTapCounter >= 4 {
                spamCooldownUntil = now.addingTimeInterval(4.0)
                mindfulWarningMessage = "تمهّل قليلاً.. الذكر بالقلب واللسان وليس بسرعة الضغط 🌿"
            }
            return false
        }

        // Auto-clicker variance detector
        if lastTapDate != .distantPast && interval < 3.0 {
            recentIntervals.append(interval)
            if recentIntervals.count > 6 { recentIntervals.removeFirst() }
            if recentIntervals.count == 6 {
                let mn = recentIntervals.min() ?? 0
                let mx = recentIntervals.max() ?? 0
                let avg = recentIntervals.reduce(0, +) / 6.0
                if (mx - mn) < 0.018 && avg < 0.90 {
                    spamCooldownUntil = now.addingTimeInterval(6.0)
                    recentIntervals.removeAll()
                    mindfulWarningMessage = "تمهّل قليلاً.. الذكر بالقلب واللسان وليس بسرعة الضغط 🌿"
                    return false
                }
            }
        }

        if now.timeIntervalSince(minuteWindowStart) >= 60.0 {
            minuteWindowStart = now
            tapsInCurrentMinute = 0
        }
        if tapsInCurrentMinute >= 130 {
            mindfulWarningMessage = "تمهّل قليلاً.. استشعر معنى الذكر بقلبك 🌿"
            return false
        }
        tapsInCurrentMinute += 1
        rapidTapCounter = 0
        lastTapDate = now
        mindfulWarningMessage = nil

        rollDayIfNeeded()
        state.totalIstighfar += 1
        state.todayCount += 1
        state.lastTapTimestamp = now.timeIntervalSince1970
        let activeId = state.activeDhikrId
        state.dhikrLifetimeCounts[activeId, default: 0] += 1
        state.historyLog[Self.todayDateKey()] = state.todayCount

        // Distinct eyes-free haptics ONLY on real milestones (never every frame!)
        if state.dailyGoal > 0 && state.todayCount == state.dailyGoal {
            HapticsAndAudio.shared.goalCompletedFeedback()
        } else if state.todayCount > 0 && state.todayCount % 100 == 0 {
            HapticsAndAudio.shared.hundredMilestoneFeedback()
        } else if state.todayCount > 0 && state.todayCount % 33 == 0 {
            HapticsAndAudio.shared.mediumPulse()
        } else {
            HapticsAndAudio.shared.tapFeedback()
        }

        // Chapter 2 Unlock at 15,000 Dhikr -> Building the Blessed Arab Mosque!
        if state.totalIstighfar >= 15_000 && !state.hasUnlockedMosqueChapter {
            state.hasUnlockedMosqueChapter = true
            showMosqueChapterCelebration = true
            HapticsAndAudio.shared.goalCompletedFeedback()
        }

        // 100,000 Full Cycle Medal
        if state.totalIstighfar >= Int64(Self.cycleTarget) && !state.hasClaimedCurrentCycleMedal {
            state.hasClaimedCurrentCycleMedal = true
            state.completedCyclesCount += 1
            showCycleCelebration = true
            HapticsAndAudio.shared.goalCompletedFeedback()
            refreshLeaderboardAndConfig()
        }

        scheduleSave()
        return true
    }

    func isHabitDone(dateKey: String, habitKey: String) -> Bool {
        state.dailyHabitsLog[dateKey]?[habitKey] ?? false
    }

    func toggleHabit(dateKey: String, habitKey: String) {
        var dayMap = state.dailyHabitsLog[dateKey] ?? [:]
        dayMap[habitKey] = !(dayMap[habitKey] ?? false)
        state.dailyHabitsLog[dateKey] = dayMap
        HapticsAndAudio.shared.gentleTick()
        scheduleSave()
    }

    func setHabitDone(dateKey: String, habitKey: String, done: Bool) {
        var dayMap = state.dailyHabitsLog[dateKey] ?? [:]
        dayMap[habitKey] = done
        state.dailyHabitsLog[dateKey] = dayMap
        scheduleSave()
    }

    func countDone(dateKey: String, keys: [String]) -> Int {
        keys.filter { isHabitDone(dateKey: dateKey, habitKey: $0) }.count
    }

    /// Rebalanced 100% Worship Score (No Fasting): Prayers 50% + Adhkar 15% + Quran 15% + Daily 10% + Sunnah 10%
    func dailyHabitScore(dateKey: String) -> Int {
        let p = Double(countDone(dateKey: dateKey, keys: ["fajr", "dhuhr", "asr", "maghrib", "isha"])) / 5.0 * 50.0
        let a = Double(countDone(dateKey: dateKey, keys: ["adhkar_morning", "adhkar_evening", "adhkar_sleep"])) / 3.0 * 15.0
        let q = isHabitDone(dateKey: dateKey, habitKey: "quran_daily") ? 15.0 : 0.0
        let d = isHabitDone(dateKey: dateKey, habitKey: "duha") ? 10.0 : 0.0
        let s = Double(countDone(dateKey: dateKey, keys: ["sunnah_fajr", "sunnah_dhuhr_pre", "sunnah_dhuhr_post", "sunnah_maghrib", "sunnah_isha", "qiyam", "witr"])) / 7.0 * 10.0
        return min(100, Int((p + a + q + d + s).rounded()))
    }

    func refreshLeaderboardAndConfig() {
        Task {
            let result = await SupabaseService.shared.syncAndFetchTop30(state: state)
            self.leaderboardOnline = result.online
            self.leaderboard = result.entries

            if let cfg = await SupabaseService.shared.checkRemoteConfig(),
               let title = cfg.announcement_title, !title.isEmpty {
                let seenKey = "midrar_ios_seen_ann_id"
                let lastSeen = UserDefaults.standard.integer(forKey: seenKey)
                let aid = cfg.announcement_id ?? 0
                if aid > lastSeen {
                    UserDefaults.standard.set(aid, forKey: seenKey)
                    self.activeAnnouncement = cfg
                }
            }
        }
    }

    func saveImmediate() {
        saveTask?.cancel()
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
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
            state.todayCount = 0
            state.lastActiveDate = today
        }
    }

    nonisolated static func todayDateKey() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.string(from: Date())
    }
}
