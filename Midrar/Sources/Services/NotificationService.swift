import Foundation
import UserNotifications

final class MidrarNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = MidrarNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Always present native iOS top banner + sound, never an intrusive center modal
        completionHandler([.banner, .sound])
    }
}

enum NotificationService {
    static func configureDelegate() {
        UNUserNotificationCenter.current().delegate = MidrarNotificationDelegate.shared
    }

    static func requestAndSchedule(state: AppState) {
        configureDelegate()
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            rescheduleAll(state: state)
        }
    }

    static func rescheduleAll(state: AppState) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard state.settings.smartReminders else { return }

        let isFemale = state.userGender == "female"
        let firstName = state.userName.split(separator: " ").first.map(String.init) ?? ""
        let yaName = firstName.isEmpty ? "" : "يا \(firstName)، "

        let prayers = PrayerTimeCalculator.computeForToday(cityName: state.settings.userCity)
        let prayerItems: [(String, Int, String, String)] = [
            ("fajr", prayers.fajrMin + 15, "أذكار بعد صلاة الفجر", "\(yaName)بعد الفجر تُقسَّم الأرزاق.. استغفر\(isFemale ? "ي" : "") ربك\(isFemale ? "ِ" : "") الآن"),
            ("dhuhr", prayers.dhuhrMin + 15, "سكينة بعد صلاة الظهر", "\(yaName)دقائق من الاستغفار بعد الظهر تشرح الصدر"),
            ("asr", prayers.asrMin + 15, "نفحة ذكر بعد العصر", "\(yaName)لا تنسَ أذكار المساء والاستغفار بعد العصر"),
            ("maghrib", prayers.maghribMin + 12, "طمأنينة بعد المغرب", "\(yaName)مع غروب الشمس ارفع\(isFemale ? "ي" : "") قلبك\(isFemale ? "ِ" : "") بالاستغفار والتسبيح"),
            ("isha", prayers.ishaMin + 15, "ختام يومك بعد العشاء", "\(yaName)اختم\(isFemale ? "ي" : "") يومك\(isFemale ? "ِ" : "") باستغفار يغسل الهموم")
        ]

        for (id, mins, title, body) in prayerItems {
            scheduleDaily(id: "prayer_\(id)", minutesFromMidnight: mins, title: title, body: body)
        }

        if state.settings.habitRemindersEnabled {
            scheduleDaily(id: "habit_morning", minutesFromMidnight: 7 * 60 + 30, title: "أذكار الصباح", body: "\(yaName)ابدأ\(isFemale ? "ي" : "") يومك\(isFemale ? "ِ" : "") بأذكار الصباح في مدرار")
            scheduleDaily(id: "habit_duha", minutesFromMidnight: prayers.sunriseMin + 25, title: "وقت صلاة الضحى", body: "\(yaName)أشرقت الشمس وحان وقت صلاة الضحى")
            scheduleDaily(id: "habit_night", minutesFromMidnight: 22 * 60 + 15, title: "أذكار النوم وصلاة الوتر", body: "\(yaName)لا تنسَ أذكار النوم وركعة الوتر ومتابعة عباداتك")
        }
    }

    private static func scheduleDaily(id: String, minutesFromMidnight: Int, title: String, body: String) {
        let m = ((minutesFromMidnight % 1440) + 1440) % 1440
        var comps = DateComponents()
        comps.hour = m / 60
        comps.minute = m % 60

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}
