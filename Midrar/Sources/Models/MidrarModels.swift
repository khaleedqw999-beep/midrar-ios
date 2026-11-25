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
    let effectType: Int // 0=Rain, 1=Tasbih, 2=Salawat, 3=Hawqalah
    var isCustom: Bool = false

    static let defaults: [DhikrItem] = [
        DhikrItem(id: "istighfar_1", arabicText: "أستغفر الله العظيم وأتوب إليه", shortTitle: "أستغفر الله", virtue: "﴿فَقُلْتُ اسْتَغْفِرُوا رَبَّكُمْ إِنَّهُ كَانَ غَفَّارًا ۝ يُرْسِلِ السَّمَاءَ عَلَيْكُم مِّدْرَارًا﴾", effectType: 0),
        DhikrItem(id: "tasbih_1", arabicText: "سبحان الله وبحمده، سبحان الله العظيم", shortTitle: "سبحان الله", virtue: "كلمتان خفيفتان على اللسان ثقيلتان في الميزان حبيبتان إلى الرحمن", effectType: 1),
        DhikrItem(id: "salat_nabi", arabicText: "اللهم صلِّ وسلم على نبينا محمد", shortTitle: "صلِّ على النبي ﷺ", virtue: "من صلى عليَّ صلاة صلى الله عليه بها عشراً", effectType: 2),
        DhikrItem(id: "hawqalah", arabicText: "لا حول ولا قوة إلا بالله", shortTitle: "لا حول ولا قوة إلا بالله", virtue: "كنز من كنوز الجنة وتفويض الأمر لله", effectType: 3),
        DhikrItem(id: "tahlil", arabicText: "لا إله إلا الله وحده لا شريك له", shortTitle: "لا إله إلا الله", virtue: "أفضل الذكر لا إله إلا الله، تجدد الإيمان وتشرح الصدر", effectType: 1)
    ]
}

struct AdhkarEntry: Identifiable {
    let id = UUID()
    let text: String
    let virtue: String
    let targetCount: Int

    static let morning: [AdhkarEntry] = [
        AdhkarEntry(text: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ", virtue: "ذكر الصباح الجامع", targetCount: 1),
        AdhkarEntry(text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ", virtue: "يُكرّر ٣ مرات صباحاً", targetCount: 3),
        AdhkarEntry(text: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ", virtue: "حفظٌ من كل سوء (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ", virtue: "كفاه الله ما أهمّه (٧ مرات)", targetCount: 7),
        AdhkarEntry(text: "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ", virtue: "توبة واستفتاح للبركة (١٠ مرات)", targetCount: 10)
    ]

    static let evening: [AdhkarEntry] = [
        AdhkarEntry(text: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ", virtue: "ذكر المساء الجامع", targetCount: 1),
        AdhkarEntry(text: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ", virtue: "حصن المساء (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ", virtue: "حفظٌ من كل سوء (٣ مرات)", targetCount: 3),
        AdhkarEntry(text: "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ", virtue: "كفاه الله ما أهمّه (٧ مرات)", targetCount: 7),
        AdhkarEntry(text: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ", virtue: "عشر صلوات تُدرك بها الشفاعة", targetCount: 10)
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
    var userCity: String = "عدن"
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
    var duas: [DuaItem] = []
    var userId: String = UUID().uuidString
    var userName: String = ""
    var userAge: Int = 0
    var userGender: String = "male"
    var hasCompletedOnboarding: Bool = false
    var historyLog: [String: Int] = [:]
    var settings: AppSettings = AppSettings()
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
