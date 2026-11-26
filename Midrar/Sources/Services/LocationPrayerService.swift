import Foundation
import CoreLocation

@MainActor
final class LocationPrayerService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationPrayerService()

    @Published var isSyncing: Bool = false
    @Published var lastStatusMessage: String?

    private let manager = CLLocationManager()
    private var onLocationResult: ((Double, Double, String?) -> Void)?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestAndSync(store: MidrarStore, userTriggered: Bool) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startFetch(store: store, userTriggered: userTriggered)
        case .notDetermined:
            if userTriggered || store.state.hasCompletedOnboarding {
                onLocationResult = { [weak store] lat, lon, city in
                    guard let store = store else { return }
                    Task { @MainActor in
                        await self.fetchOnlineTimings(store: store, lat: lat, lon: lon, detectedCity: city)
                    }
                }
                manager.requestWhenInUseAuthorization()
            }
        default:
            if userTriggered {
                lastStatusMessage = "يرجى تفعيل صلاحية الموقع لمدرار من إعدادات الآيفون"
            }
        }
    }

    private func startFetch(store: MidrarStore, userTriggered: Bool) {
        let today = MidrarStore.todayDateKey()
        if !userTriggered && store.state.settings.cachedPrayerDate == today && store.state.settings.cachedFajrMin >= 0 {
            return
        }
        isSyncing = true
        onLocationResult = { [weak store] lat, lon, city in
            guard let store = store else { return }
            Task { @MainActor in
                await self.fetchOnlineTimings(store: store, lat: lat, lon: lon, detectedCity: city)
            }
        }
        manager.requestLocation()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let st = manager.authorizationStatus
        if st == .authorizedWhenInUse || st == .authorizedAlways {
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc, preferredLocale: Locale(identifier: "ar")) { placemarks, _ in
            let p = placemarks?.first
            let name = p?.locality ?? p?.subAdministrativeArea ?? p?.administrativeArea
            Task { @MainActor in
                self.onLocationResult?(lat, lon, name)
                self.onLocationResult = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isSyncing = false
        }
    }

    private func fetchOnlineTimings(store: MidrarStore, lat: Double, lon: Double, detectedCity: String?) async {
        defer { isSyncing = false }
        store.state.settings.autoLocationPrayerTimes = true
        store.state.settings.userLat = lat
        store.state.settings.userLon = lon
        if let c = detectedCity, !c.isEmpty {
            store.state.settings.detectedLocationName = c
            store.state.settings.userCity = c
        }

        let df = DateFormatter()
        df.dateFormat = "dd-MM-yyyy"
        df.locale = Locale(identifier: "en_US_POSIX")
        let dateStr = df.string(from: Date())
        let urlStr = String(format: "https://api.aladhan.com/v1/timings/%@?latitude=%.5f&longitude=%.5f&method=4", dateStr, lat, lon)
        guard let url = URL(string: urlStr) else { return }

        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            if (resp as? HTTPURLResponse)?.statusCode == 200,
               let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dObj = root["data"] as? [String: Any],
               let timings = dObj["timings"] as? [String: Any] {
                let f = parseHm(timings["Fajr"] as? String)
                let sr = parseHm(timings["Sunrise"] as? String)
                let dh = parseHm(timings["Dhuhr"] as? String)
                let asr = parseHm(timings["Asr"] as? String)
                let mg = parseHm(timings["Maghrib"] as? String)
                let ish = parseHm(timings["Isha"] as? String)
                if f >= 0 && dh >= 0 && asr >= 0 && mg >= 0 && ish >= 0 {
                    store.state.settings.cachedPrayerDate = MidrarStore.todayDateKey()
                    store.state.settings.cachedFajrMin = f
                    store.state.settings.cachedSunriseMin = sr >= 0 ? sr : (f + 75)
                    store.state.settings.cachedDhuhrMin = dh
                    store.state.settings.cachedAsrMin = asr
                    store.state.settings.cachedMaghribMin = mg
                    store.state.settings.cachedIshaMin = ish
                }
            }
        } catch {
            // Graceful offline coordinate fallback
        }

        store.saveImmediate()
        NotificationService.rescheduleAll(state: store.state)
        let label = detectedCity ?? "موقعك الحالي"
        lastStatusMessage = "تم ضبط المواقيت تلقائياً على \(label) 📍"
    }

    private func parseHm(_ raw: String?) -> Int {
        guard let raw = raw else { return -1 }
        let clean = raw.split(separator: " ").first.map(String.init) ?? raw
        let parts = clean.split(separator: ":")
        guard parts.count >= 2,
              let h = Int(parts[0].filter(\.isNumber)),
              let m = Int(parts[1].filter(\.isNumber)) else { return -1 }
        return h * 60 + m
    }
}
