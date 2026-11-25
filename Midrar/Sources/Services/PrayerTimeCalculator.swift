import Foundation

struct CityCoords {
    let name: String
    let lat: Double
    let lng: Double
    let tz: Double
}

struct DailyPrayers {
    let fajrMin: Int
    let sunriseMin: Int
    let dhuhrMin: Int
    let asrMin: Int
    let maghribMin: Int
    let ishaMin: Int
}

enum PrayerTimeCalculator {
    static let cities: [CityCoords] = [
        CityCoords(name: "عدن", lat: 12.7855, lng: 45.0187, tz: 3),
        CityCoords(name: "صنعاء", lat: 15.3694, lng: 44.1910, tz: 3),
        CityCoords(name: "تعز", lat: 13.5789, lng: 44.0178, tz: 3),
        CityCoords(name: "المكلا", lat: 14.5425, lng: 49.1242, tz: 3),
        CityCoords(name: "الحديدة", lat: 14.7978, lng: 42.9545, tz: 3),
        CityCoords(name: "إب", lat: 13.9667, lng: 44.1833, tz: 3),
        CityCoords(name: "مكة المكرمة", lat: 21.4225, lng: 39.8262, tz: 3),
        CityCoords(name: "المدينة المنورة", lat: 24.4672, lng: 39.6112, tz: 3),
        CityCoords(name: "الرياض", lat: 24.7136, lng: 46.6753, tz: 3),
        CityCoords(name: "جدة", lat: 21.5433, lng: 39.1728, tz: 3),
        CityCoords(name: "الدمام", lat: 26.4207, lng: 50.0888, tz: 3),
        CityCoords(name: "القاهرة", lat: 30.0444, lng: 31.2357, tz: 2),
        CityCoords(name: "الإسكندرية", lat: 31.2001, lng: 29.9187, tz: 2),
        CityCoords(name: "دبي", lat: 25.2048, lng: 55.2708, tz: 4),
        CityCoords(name: "أبوظبي", lat: 24.4539, lng: 54.3773, tz: 4),
        CityCoords(name: "الدوحة", lat: 25.2854, lng: 51.5310, tz: 3),
        CityCoords(name: "مسقط", lat: 23.5880, lng: 58.3829, tz: 4),
        CityCoords(name: "عمّان", lat: 31.9539, lng: 35.9106, tz: 3),
        CityCoords(name: "بغداد", lat: 33.3152, lng: 44.3661, tz: 3),
        CityCoords(name: "الكويت", lat: 29.3759, lng: 47.9774, tz: 3)
    ]

    static func computeForToday(cityName: String) -> DailyPrayers {
        let city = cities.first(where: { $0.name == cityName }) ?? cities[0]
        let now = Date()
        let cal = Calendar(identifier: .gregorian)
        let y = Double(cal.component(.year, from: now))
        let m = Double(cal.component(.month, from: now))
        let d = Double(cal.component(.day, from: now))

        let jd = julianDay(year: y, month: m, day: d)
        let D = jd - 2451545.0
        let g = fixAngle(357.529 + 0.98560028 * D)
        let q = fixAngle(280.459 + 0.98564736 * D)
        let L = fixAngle(q + 1.915 * sinDeg(g) + 0.020 * sinDeg(2 * g))
        let e = 23.439 - 0.00000036 * D
        let decl = rad2deg(asin(sinDeg(e) * sinDeg(L)))

        let ra = rad2deg(atan2(cosDeg(e) * sinDeg(L), cosDeg(L))) / 15.0
        let eqt = q / 15.0 - fixHour(ra)

        let dhuhrHours = fixHour(12.0 + city.tz - city.lng / 15.0 - eqt)
        let sunriseHours = dhuhrHours - sunAngleTime(angle: 0.833, lat: city.lat, decl: decl)
        let sunsetHours = dhuhrHours + sunAngleTime(angle: 0.833, lat: city.lat, decl: decl)
        let fajrHours = dhuhrHours - sunAngleTime(angle: 18.5, lat: city.lat, decl: decl)
        let asrHours = dhuhrHours + asrTime(factor: 1.0, lat: city.lat, decl: decl)
        let ishaHours = sunsetHours + 1.5

        return DailyPrayers(
            fajrMin: toMin(fajrHours),
            sunriseMin: toMin(sunriseHours),
            dhuhrMin: toMin(dhuhrHours),
            asrMin: toMin(asrHours),
            maghribMin: toMin(sunsetHours),
            ishaMin: toMin(ishaHours)
        )
    }

    static func formatTime12h(_ totalMinutes: Int) -> String {
        let m = ((totalMinutes % 1440) + 1440) % 1440
        let h24 = m / 60
        let min = m % 60
        let h12 = (h24 == 0) ? 12 : (h24 > 12 ? h24 - 12 : h24)
        return String(format: "%d:%02d", h12, min)
    }

    private static func toMin(_ hours: Double) -> Int {
        Int((fixHour(hours) * 60.0).rounded()) % 1440
    }

    private static func sunAngleTime(angle: Double, lat: Double, decl: Double) -> Double {
        let num = -sinDeg(angle) - sinDeg(lat) * sinDeg(decl)
        let den = cosDeg(lat) * cosDeg(decl)
        let val = max(-1.0, min(1.0, num / den))
        return rad2deg(acos(val)) / 15.0
    }

    private static func asrTime(factor: Double, lat: Double, decl: Double) -> Double {
        let angle = -rad2deg(atan(1.0 / (factor + tanDeg(abs(lat - decl)))))
        return sunAngleTime(angle: angle, lat: lat, decl: decl)
    }

    private static func julianDay(year: Double, month: Double, day: Double) -> Double {
        var y = year
        var m = month
        if m <= 2 { y -= 1; m += 12 }
        let A = floor(y / 100.0)
        let B = 2.0 - A + floor(A / 4.0)
        return floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + day + B - 1524.5
    }

    private static func sinDeg(_ d: Double) -> Double { sin(d * .pi / 180.0) }
    private static func cosDeg(_ d: Double) -> Double { cos(d * .pi / 180.0) }
    private static func tanDeg(_ d: Double) -> Double { tan(d * .pi / 180.0) }
    private static func rad2deg(_ r: Double) -> Double { r * 180.0 / .pi }
    private static func fixAngle(_ a: Double) -> Double {
        var res = a.truncatingRemainder(dividingBy: 360.0)
        if res < 0 { res += 360.0 }
        return res
    }
    private static func fixHour(_ h: Double) -> Double {
        var res = h.truncatingRemainder(dividingBy: 24.0)
        if res < 0 { res += 24.0 }
        return res
    }
}
