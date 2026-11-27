import SwiftUI
import CoreLocation

final class CompassHeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var smoothedHeading: Double = 0
    @Published var unwrappedDialAngle: Double = 0
    @Published var isTrueNorth: Bool = false
    @Published var headingAccuracy: Double = -1
    @Published var liveLat: Double?
    @Published var liveLon: Double?
    @Published var isAvailable: Bool = CLLocationManager.headingAvailable()

    private let manager = CLLocationManager()
    private var sinAvg: Double = 0
    private var cosAvg: Double = 1
    private var hasInitialHeading = false
    private let alpha: Double = 0.18

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 0.5
        manager.headingOrientation = .portrait
    }

    func start() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        // Starting location updates is REQUIRED by CoreLocation so newHeading.trueHeading is computed (True North instead of Magnetic North).
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.liveLat = loc.coordinate.latitude
            self.liveLon = loc.coordinate.longitude
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let acc = newHeading.headingAccuracy
        let usingTrue = newHeading.trueHeading >= 0
        let rawDeg = usingTrue ? newHeading.trueHeading : newHeading.magneticHeading
        guard acc >= 0 else {
            DispatchQueue.main.async { self.headingAccuracy = acc }
            return
        }

        let rad = rawDeg * .pi / 180.0
        if !hasInitialHeading {
            sinAvg = sin(rad)
            cosAvg = cos(rad)
            hasInitialHeading = true
        } else {
            sinAvg = sinAvg * (1.0 - alpha) + sin(rad) * alpha
            cosAvg = cosAvg * (1.0 - alpha) + cos(rad) * alpha
        }
        var filtered = atan2(sinAvg, cosAvg) * 180.0 / .pi
        if filtered < 0 { filtered += 360.0 }

        DispatchQueue.main.async {
            // Unwrap continuous angle so SwiftUI never spins 358° backward across 0°/360°
            var delta = -filtered - self.unwrappedDialAngle
            delta = delta.truncatingRemainder(dividingBy: 360.0)
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }

            self.unwrappedDialAngle += delta
            self.smoothedHeading = filtered
            self.isTrueNorth = usingTrue
            self.headingAccuracy = acc
        }
    }
}

struct QiblaCompassView: View {
    @EnvironmentObject var store: MidrarStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var compass = CompassHeadingManager()
    @State private var didVibrateAligned = false

    private var userCoords: (lat: Double, lon: Double, label: String) {
        let s = store.state.settings
        if let lat = compass.liveLat, let lon = compass.liveLon, (abs(lat) > 0.001 || abs(lon) > 0.001) {
            let lbl = !s.detectedLocationName.isEmpty ? s.detectedLocationName : (!s.userCity.isEmpty ? s.userCity : "موقعك المباشر GPS")
            return (lat, lon, lbl)
        }
        if s.autoLocationPrayerTimes && (abs(s.userLat) > 0.001 || abs(s.userLon) > 0.001) {
            return (s.userLat, s.userLon, s.detectedLocationName.isEmpty ? s.userCity : s.detectedLocationName)
        }
        let city = PrayerTimeCalculator.cities.first(where: { $0.name == s.userCity }) ?? PrayerTimeCalculator.cities[0]
        return (city.lat, city.lng, city.name)
    }

    /// Exact great-circle azimuth from user's coordinates to the Holy Kaaba (21.422487° N, 39.826206° E)
    private var qiblaBearing: Double {
        let lat1 = userCoords.lat * .pi / 180.0
        let lon1 = userCoords.lon * .pi / 180.0
        let lat2 = 21.422487 * .pi / 180.0
        let lon2 = 39.826206 * .pi / 180.0
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var deg = atan2(y, x) * 180.0 / .pi
        if deg < 0 { deg += 360.0 }
        return deg
    }

    private var relativeQiblaAngle: Double {
        var diff = qiblaBearing - compass.smoothedHeading
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    private var isAligned: Bool {
        compass.headingAccuracy >= 0 && abs(relativeQiblaAngle) <= 3.5
    }

    private var needsCalibration: Bool {
        compass.headingAccuracy < 0 || compass.headingAccuracy > 22
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("اتجاه القبلة")
                    .font(.system(size: 22, weight: .heavy))
                Spacer()
                Button("إغلاق") { dismiss() }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(store.accentColor)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            VStack(spacing: 4) {
                Text("موقعك: \(userCoords.label)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(store.accentColor)
                Text("زاوية القبلة: \(Int(qiblaBearing.rounded()))° • \(compass.isTrueNorth ? "الشمال الحقيقي ✓" : "الشمال المغناطيسي")")
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
            }

            if needsCalibration {
                Text("⚠️ حرّك الهاتف بهدوء على شكل رقم 8 بعيداً عن المغناطيس لمعايرة البوصلة")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(Color(hex: "C68A2E"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: "C68A2E").opacity(0.14)))
            }

            Spacer()

            // Fixed top alignment pointer (exact 12 o'clock center of phone)
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isAligned ? store.accentColor : Color(hex: "C68A2E"))
                .padding(.bottom, -10)

            // Luminous Compass Dial (LTR internal geometry so East=right, West=left accurately)
            ZStack {
                Circle()
                    .fill(Color.cardSurface)
                    .frame(width: 284, height: 284)
                    .overlay(
                        Circle()
                            .stroke(isAligned ? store.accentColor : Color.cardBorder, lineWidth: isAligned ? 4 : 1.5)
                    )
                    .shadow(color: isAligned ? store.accentColor.opacity(0.32) : Color.black.opacity(0.08), radius: isAligned ? 24 : 12)

                // Rotating Dial: Cardinal directions + Golden Kaaba Pointer locked to qiblaBearing on the dial!
                // Because the Kaaba needle is placed at qiblaBearing INSIDE the dial rotating by unwrappedDialAngle (-heading),
                // it NEVER wraps backward across 0°/360° and always stays 100% locked to True North + Qibla!
                ZStack {
                    ForEach(0..<36, id: \.self) { tick in
                        Rectangle()
                            .fill(tick == 0 ? Color.red.opacity(0.85) : (tick % 9 == 0 ? store.accentColor : Color.secondary.opacity(0.28)))
                            .frame(width: tick % 9 == 0 ? 2.5 : 1, height: tick % 9 == 0 ? 14 : 7)
                            .offset(y: -126)
                            .rotationEffect(.degrees(Double(tick) * 10))
                    }
                    Text("ش").font(.system(size: 13, weight: .bold)).foregroundColor(.red.opacity(0.85)).offset(y: -104)
                    Text("ج").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).offset(y: 104)
                    Text("ق").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).offset(x: 104)
                    Text("غ").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).offset(x: -104)

                    // Kaaba Needle fixed at exact qiblaBearing on the North-up dial
                    VStack(spacing: 4) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(isAligned ? store.accentColor : Color(hex: "C68A2E"))
                        Capsule()
                            .fill(isAligned ? store.accentColor : Color(hex: "C68A2E"))
                            .frame(width: 5, height: 76)
                    }
                    .offset(y: -46)
                    .rotationEffect(.degrees(qiblaBearing))
                }
                .environment(\.layoutDirection, .leftToRight)
                .rotationEffect(.degrees(compass.unwrappedDialAngle))
                .animation(.linear(duration: 0.08), value: compass.unwrappedDialAngle)

                Circle()
                    .fill(isAligned ? store.accentColor : Color(hex: "C68A2E"))
                    .frame(width: 14, height: 14)
            }

            Text(isAligned ? "أنت الآن باتجاه القبلة تماماً ✓" : (relativeQiblaAngle > 0 ? "أدِر الهاتف قليلاً لليمين (\(Int(abs(relativeQiblaAngle).rounded()))°)" : "أدِر الهاتف قليلاً لليسار (\(Int(abs(relativeQiblaAngle).rounded()))°)"))
                .font(.system(size: 14.5, weight: .bold))
                .foregroundColor(isAligned ? store.accentColor : .secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(isAligned ? store.accentColor.opacity(0.14) : Color.cardSurface))

            Spacer()

            Text("أمسك الهاتف مستوياً وبعيداً عن المعادن والمغناطيس لأعلى دقة")
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)
                .padding(.bottom, 22)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear { compass.start() }
        .onDisappear { compass.stop() }
        .onChange(of: isAligned) { aligned in
            if aligned && !didVibrateAligned {
                didVibrateAligned = true
                HapticsAndAudio.shared.mediumPulse()
            } else if !aligned {
                didVibrateAligned = false
            }
        }
    }
}
