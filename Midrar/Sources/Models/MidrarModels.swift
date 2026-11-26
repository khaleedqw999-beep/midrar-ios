import Foundation
import SwiftUI
import UIKit

enum AccentPalette: String, Codable, CaseIterable, Identifiable {
    case auto = "auto"
    case olive = "olive"
    case blue = "blue"
    case rose = "rose"
    case sand = "sand"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "تلقائي"
        case .olive: return "زيتوني"
        case .blue: return "سماوي"
        case .rose: return "وردي"
        case .sand: return "رملي"
        }
    }

    func color(isFemale: Bool) -> Color {
        switch self {
        case .auto: return isFemale ? Color(hex: "C8467C") : Color(hex: "4A6741")
        case .olive: return Color(hex: "4A6741")
        case .blue: return Color(hex: "1D72D2")
        case .rose: return Color(hex: "C8467C")
        case .sand: return Color(hex: "9A6B2F")
        }
    }
}

enum AppColorSchemeMode: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"

    var label: String {
        switch self {
        case .light: return "نهاري"
        case .dark: return "ليلي"
        case .auto: return "تلقائي"
        }
    }
}

struct DhikrItem: Identifiable, Codable, Hashable {
    let id: String
    let arabicText: String
    let shortTitle: String
    let virtue: String
    let effectType: Int
    var isCustom: Bool = false

    static let defaults: [DhikrItem] = [
        DhikrItem(id: "istighfar_1", arabicText: "أستغفر الله العظيم وأتوب إليه", shortTitle: "أستغفر الله", virtue: "﴿فَقُلْتُ اسْتَغْفِرُوا رَبَّكُمْ إِنَّهُ كَانَ غَفَّارًا ۝ يُرْسِلِ السَّمَاءَ عَلَيْكُم مِّدْرَارًا﴾", effectType: 0),
        DhikrItem(id: "tasbih_1", arabicText: "سبحان الله وبحمده، سبحان الله العظيم", shortTitle: "سبحان الله", virtue: "كلمتان خفيفتان على اللسان ثقيلتان في الميزان حبيبتان إلى الرحمن", effectType: 1),
        DhikrItem(id: "salat_nabi", arabicText: "اللهم صلِّ وسلم على نبينا محمد", shortTitle: "صلِّ على النبي ﷺ", virtue: "من صلى عليَّ صلاة صلى الله عليه بها عشراً", effectType: 2),
        DhikrItem(id: "hawqalah", arabicText: "لا حول ولا قوة إلا بالله", shortTitle: "لا حول ولا قوة إلا بالله", virtue: "كنز من كنوز الجنة وتفويض الأمر لله", effectType: 3),
        DhikrItem(id: "tahlil", arabicText: "لا إله إلا الله وحده لا شريك له", shortTitle: "لا إله إلا الله", virtue: "أفضل الذكر لا إله إلا الله، تجدد الإيمان وتشرح الصدر", effectType: 1)
    ]
}

enum AdhkarSessionMode {
    case morning
    case evening
    case sleep

    var title: String {
        switch self {
        case .morning: return "أذكار الصباح"
        case .evening: return "أذكار المساء"
        case .sleep: return "أذكار النوم"
        }
    }

    var habitKey: String {
        switch self {
        case .morning: return "adhkar_morning"
        case .evening: return "adhkar_evening"
        case .sleep: return "adhkar_sleep"
        }
    }

    var entries: [AdhkarEntry] {
        switch self {
        case .morning: return AdhkarEntry.morning
        case .evening: return AdhkarEntry.evening
        case .sleep: return AdhkarEntry.sleep
        }
    }
}

struct AdhkarEntry: Identifiable {
    let id = UUID()
    let text: String
    let virtue: String
    let targetCount: Int

    static let morning: [AdhkarEntry] = [
        AdhkarEntry(text: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ", virtue: "آية الكرسي — أُجير من الجن حتى يمسي", targetCount: 1),
        AdhkarEntry(text: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ", virtue: "ذكر الصباح الجامع", targetCount: 1),
        AdhkarEntry(text: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ", virtue: "سيد الاستغفار", targetCount: 1),
        AdhkarEntry(text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ", virtue: "يُكرّر ٣ مرات صباحاً", targetCount: 3),
        AdhkarEntry(text: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ", virtue: "حفظٌ من كل سوء (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ", virtue: "كفاه الله ما أهمّه (٧ مرات)", targetCount: 7),
        AdhkarEntry(text: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ", virtue: "أدركته شفاعة النبي ﷺ (١٠ مرات)", targetCount: 10)
    ]

    static let evening: [AdhkarEntry] = [
        AdhkarEntry(text: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ", virtue: "آية الكرسي — أُجير من الجن حتى يصبح", targetCount: 1),
        AdhkarEntry(text: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ", virtue: "ذكر المساء الجامع", targetCount: 1),
        AdhkarEntry(text: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ", virtue: "حصن المساء (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ", virtue: "حفظٌ من كل سوء (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ", virtue: "كفاه الله ما أهمّه (٧ مرات)", targetCount: 7),
        AdhkarEntry(text: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ", virtue: "عشر صلوات تُدرك بها الشفاعة", targetCount: 10)
    ]

    static let sleep: [AdhkarEntry] = [
        AdhkarEntry(text: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ", virtue: "آية الكرسي — لا يزال عليك من الله حافظ حتى تصبح", targetCount: 1),
        AdhkarEntry(text: "آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّن رُّسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ", virtue: "آخر آيتين من سورة البقرة — من قرأهما في ليلة كفتاه", targetCount: 1),
        AdhkarEntry(text: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ", virtue: "سورة الإخلاص (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ", virtue: "سورة الفلق (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ", virtue: "سورة الناس (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ", virtue: "دعاء النوم في حفظ الله", targetCount: 1),
        AdhkarEntry(text: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ", virtue: "يُقال ٣ مرات قبل النوم", targetCount: 3),
        AdhkarEntry(text: "سُبْحَانَ اللَّهِ", virtue: "تسبيح قبل النوم (٣٣ مرة)", targetCount: 33),
        AdhkarEntry(text: "الْحَمْدُ لِلَّهِ", virtue: "تحميد قبل النوم (٣٣ مرة)", targetCount: 33),
        AdhkarEntry(text: "اللَّهُ أَكْبَرُ", virtue: "تكبير قبل النوم (٣٤ مرة)", targetCount: 34)
    ]
}

struct DuaItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var text: String
    var isPinned: Bool = false
}

struct LeaderboardEntry: Identifiable, Codable {
    var id: String { user_id }
    let user_id: String
    let display_name: String
    let gender: String
    let total_istighfar: Int64
    let current_streak: Int
    let oasis_stage: Int
    var updated_at: String?
}

struct RemoteAppConfig: Codable {
    let id: Int?
    let latest_version_code: Int?
    let latest_version_name: String?
    let update_url: String?
    let update_message: String?
    let announcement_id: Int?
    let announcement_title: String?
    let announcement_body: String?
}

struct AppSettings: Codable {
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var smartReminders: Bool = true
    var habitRemindersEnabled: Bool = true
    var themeMode: AppColorSchemeMode = .light
    var accentTheme: AccentPalette = .auto
    var userCity: String = "لحج"

    // Auto GPS + Live Online Prayer Times (V5.2)
    var autoLocationPrayerTimes: Bool = true
    var userLat: Double = 0.0
    var userLon: Double = 0.0
    var detectedLocationName: String = ""
    var cachedPrayerDate: String = ""
    var cachedFajrMin: Int = -1
    var cachedSunriseMin: Int = -1
    var cachedDhuhrMin: Int = -1
    var cachedAsrMin: Int = -1
    var cachedMaghribMin: Int = -1
    var cachedIshaMin: Int = -1

    // Daily Quran Wird & Mushaf (V5.2)
    var quranDailyPages: Int = 4
    var quranCurrentPage: Int = 1
    var quranPagesReadToday: Int = 0
    var quranLastReadDate: String = ""
    var quranWirdReminderEnabled: Bool = true
    var quranWirdHour: Int = 21
    var quranWirdMinute: Int = 0
    var quranFontSize: CGFloat = 22

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        smartReminders = try c.decodeIfPresent(Bool.self, forKey: .smartReminders) ?? true
        habitRemindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .habitRemindersEnabled) ?? true
        themeMode = try c.decodeIfPresent(AppColorSchemeMode.self, forKey: .themeMode) ?? .light
        accentTheme = try c.decodeIfPresent(AccentPalette.self, forKey: .accentTheme) ?? .auto
        userCity = try c.decodeIfPresent(String.self, forKey: .userCity) ?? "لحج"
        autoLocationPrayerTimes = try c.decodeIfPresent(Bool.self, forKey: .autoLocationPrayerTimes) ?? true
        userLat = try c.decodeIfPresent(Double.self, forKey: .userLat) ?? 0.0
        userLon = try c.decodeIfPresent(Double.self, forKey: .userLon) ?? 0.0
        detectedLocationName = try c.decodeIfPresent(String.self, forKey: .detectedLocationName) ?? ""
        cachedPrayerDate = try c.decodeIfPresent(String.self, forKey: .cachedPrayerDate) ?? ""
        cachedFajrMin = try c.decodeIfPresent(Int.self, forKey: .cachedFajrMin) ?? -1
        cachedSunriseMin = try c.decodeIfPresent(Int.self, forKey: .cachedSunriseMin) ?? -1
        cachedDhuhrMin = try c.decodeIfPresent(Int.self, forKey: .cachedDhuhrMin) ?? -1
        cachedAsrMin = try c.decodeIfPresent(Int.self, forKey: .cachedAsrMin) ?? -1
        cachedMaghribMin = try c.decodeIfPresent(Int.self, forKey: .cachedMaghribMin) ?? -1
        cachedIshaMin = try c.decodeIfPresent(Int.self, forKey: .cachedIshaMin) ?? -1
        quranDailyPages = try c.decodeIfPresent(Int.self, forKey: .quranDailyPages) ?? 4
        quranCurrentPage = try c.decodeIfPresent(Int.self, forKey: .quranCurrentPage) ?? 1
        quranPagesReadToday = try c.decodeIfPresent(Int.self, forKey: .quranPagesReadToday) ?? 0
        quranLastReadDate = try c.decodeIfPresent(String.self, forKey: .quranLastReadDate) ?? ""
        quranWirdReminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .quranWirdReminderEnabled) ?? true
        quranWirdHour = try c.decodeIfPresent(Int.self, forKey: .quranWirdHour) ?? 21
        quranWirdMinute = try c.decodeIfPresent(Int.self, forKey: .quranWirdMinute) ?? 0
        quranFontSize = try c.decodeIfPresent(CGFloat.self, forKey: .quranFontSize) ?? 22
    }
}

struct AppState: Codable {
    var totalIstighfar: Int64 = 0
    var todayCount: Int = 0
    var dailyGoal: Int = 500
    var currentStreak: Int = 1
    var longestStreak: Int = 1
    var lastActiveDate: String = ""
    var lastTapTimestamp: TimeInterval = 0
    var raindropsCurrency: Int = 0
    var activeDhikrId: String = "istighfar_1"
    var dhikrLifetimeCounts: [String: Int64] = [:]
    var customDhikrs: [DhikrItem] = []
    var dailyHabitsLog: [String: [String: Bool]] = [:]
    var completedCyclesCount: Int = 0
    var hasClaimedCurrentCycleMedal: Bool = false
    var hasUnlockedMosqueChapter: Bool = false
    var seasonVersion: Int = 0
    var duas: [DuaItem] = []
    var userId: String = UUID().uuidString
    var userName: String = ""
    var userAge: Int = 0
    var userGender: String = "male"
    var hasCompletedOnboarding: Bool = false
    var historyLog: [String: Int] = [:]
    var settings: AppSettings = AppSettings()

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalIstighfar = try c.decodeIfPresent(Int64.self, forKey: .totalIstighfar) ?? 0
        todayCount = try c.decodeIfPresent(Int.self, forKey: .todayCount) ?? 0
        dailyGoal = try c.decodeIfPresent(Int.self, forKey: .dailyGoal) ?? 500
        currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 1
        longestStreak = try c.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 1
        lastActiveDate = try c.decodeIfPresent(String.self, forKey: .lastActiveDate) ?? ""
        lastTapTimestamp = try c.decodeIfPresent(TimeInterval.self, forKey: .lastTapTimestamp) ?? 0
        raindropsCurrency = try c.decodeIfPresent(Int.self, forKey: .raindropsCurrency) ?? 0
        activeDhikrId = try c.decodeIfPresent(String.self, forKey: .activeDhikrId) ?? "istighfar_1"
        dhikrLifetimeCounts = try c.decodeIfPresent([String: Int64].self, forKey: .dhikrLifetimeCounts) ?? [:]
        customDhikrs = try c.decodeIfPresent([DhikrItem].self, forKey: .customDhikrs) ?? []
        dailyHabitsLog = try c.decodeIfPresent([String: [String: Bool]].self, forKey: .dailyHabitsLog) ?? [:]
        completedCyclesCount = try c.decodeIfPresent(Int.self, forKey: .completedCyclesCount) ?? 0
        hasClaimedCurrentCycleMedal = try c.decodeIfPresent(Bool.self, forKey: .hasClaimedCurrentCycleMedal) ?? false
        hasUnlockedMosqueChapter = try c.decodeIfPresent(Bool.self, forKey: .hasUnlockedMosqueChapter) ?? false
        seasonVersion = try c.decodeIfPresent(Int.self, forKey: .seasonVersion) ?? 0
        duas = try c.decodeIfPresent([DuaItem].self, forKey: .duas) ?? []
        userId = try c.decodeIfPresent(String.self, forKey: .userId) ?? UUID().uuidString
        userName = try c.decodeIfPresent(String.self, forKey: .userName) ?? ""
        userAge = try c.decodeIfPresent(Int.self, forKey: .userAge) ?? 0
        userGender = try c.decodeIfPresent(String.self, forKey: .userGender) ?? "male"
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        historyLog = try c.decodeIfPresent([String: Int].self, forKey: .historyLog) ?? [:]
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    static let appBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.055, green: 0.075, blue: 0.067, alpha: 1) : UIColor(red: 0.98, green: 0.984, blue: 0.976, alpha: 1)
    })

    static let cardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.105, green: 0.135, blue: 0.122, alpha: 1) : UIColor(red: 0.953, green: 0.961, blue: 0.949, alpha: 1)
    })

    static let cardBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.155, green: 0.20, blue: 0.18, alpha: 1) : UIColor(red: 0.898, green: 0.922, blue: 0.89, alpha: 1)
    })
}

struct TopRoundedShape: Shape {
    var radius: CGFloat = 24
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
