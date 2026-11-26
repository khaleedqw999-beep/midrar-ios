import SwiftUI
import CoreLocation

final class CompassHeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var headingDegrees: Double = 0
    @Published var isAvailable: Bool = CLLocationManager.headingAvailable()

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 1
    }

    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let deg = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        DispatchQueue.main.async {
            self.headingDegrees = deg
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
        if s.autoLocationPrayerTimes && (abs(s.userLat) > 0.001 || abs(s.userLon) > 0.001) {
            return (s.userLat, s.userLon, s.detectedLocationName.isEmpty ? s.userCity : s.detectedLocationName)
        }
        let city = PrayerTimeCalculator.cities.first(where: { $0.name == s.userCity }) ?? PrayerTimeCalculator.cities[0]
        return (city.lat, city.lng, city.name)
    }

    /// Exact spherical trigonometry bearing from user's coordinates to the Holy Kaaba (21.4225° N, 39.8262° E)
    private var qiblaBearing: Double {
        let lat1 = userCoords.lat * .pi / 180.0
        let lon1 = userCoords.lon * .pi / 180.0
        let lat2 = 21.4225 * .pi / 180.0
        let lon2 = 39.8262 * .pi / 180.0
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var deg = atan2(y, x) * 180.0 / .pi
        if deg < 0 { deg += 360.0 }
        return deg
    }

    private var relativeQiblaAngle: Double {
        var diff = qiblaBearing - compass.headingDegrees
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    private var isAligned: Bool {
        abs(relativeQiblaAngle) <= 4.5
    }

    var body: some View {
        VStack(spacing: 22) {
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
                Text("زاوية القبلة: \(Int(qiblaBearing.rounded()))° نحو مكة المكرمة")
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Luminous Compass Dial
            ZStack {
                Circle()
                    .fill(Color.cardSurface)
                    .frame(width: 280, height: 280)
                    .overlay(
                        Circle()
                            .stroke(isAligned ? store.accentColor : Color.cardBorder, lineWidth: isAligned ? 4 : 1.5)
                    )
                    .shadow(color: isAligned ? store.accentColor.opacity(0.32) : Color.black.opacity(0.08), radius: isAligned ? 24 : 12)

                // Cardinal Directions rotating with phone heading
                ZStack {
                    ForEach(0..<36, id: \.self) { tick in
                        Rectangle()
                            .fill(tick % 9 == 0 ? store.accentColor : Color.secondary.opacity(0.28))
                            .frame(width: tick % 9 == 0 ? 2.5 : 1, height: tick % 9 == 0 ? 14 : 7)
                            .offset(y: -124)
                            .rotationEffect(.degrees(Double(tick) * 10))
                    }
                    Text("ش").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).offset(y: -102)
                    Text("ج").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).offset(y: 102)
                    Text("ق").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).offset(x: 102)
                    Text("غ").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary).offset(x: -102)
                }
                .rotationEffect(.degrees(-compass.headingDegrees))
                .animation(.easeOut(duration: 0.14), value: compass.headingDegrees)

                // Golden Kaaba Qibla Pointer Needle
                VStack(spacing: 4) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isAligned ? store.accentColor : Color(hex: "C68A2E"))
                    Capsule()
                        .fill(isAligned ? store.accentColor : Color(hex: "C68A2E"))
                        .frame(width: 5, height: 78)
                }
                .offset(y: -46)
                .rotationEffect(.degrees(relativeQiblaAngle))
                .animation(.easeOut(duration: 0.14), value: relativeQiblaAngle)

                Circle()
                    .fill(isAligned ? store.accentColor : Color(hex: "C68A2E"))
                    .frame(width: 14, height: 14)
            }

            Text(isAligned ? "أنت الآن باتجاه القبلة تماماً ✓" : "أدِر الهاتف بهدوء حتى يتطابق السهم مع الأعلى")
                .font(.system(size: 14.5, weight: .bold))
                .foregroundColor(isAligned ? store.accentColor : .secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(isAligned ? store.accentColor.opacity(0.14) : Color.cardSurface))

            Spacer()

            Text("تعمل البوصلة بدون إنترنت بدقة عالية — أبعِد الهاتف عن المغناطيس")
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
