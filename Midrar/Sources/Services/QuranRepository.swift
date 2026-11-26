import Foundation

struct SurahMeta: Identifiable {
    var id: Int { number }
    let number: Int
    let name: String
    let ayahCount: Int
    let startPage: Int
    let isMeccan: Bool
}

struct QuranAyahItem: Identifiable {
    var id: String { "\(surahNumber)_\(numberInSurah)" }
    let surahNumber: Int
    let surahName: String
    let numberInSurah: Int
    let text: String
    let juz: Int
    let page: Int
    let normalizedText: String
}

struct QuranPageContent {
    let pageNumber: Int
    let juzNumber: Int
    let primarySurahName: String
    let ayahs: [QuranAyahItem]
}

final class QuranRepository {
    static let shared = QuranRepository()

    private let lock = NSLock()
    private var pagesCache: [Int: QuranPageContent] = [:]
    private var allAyahs: [QuranAyahItem] = []
    private var didLoadBundled = false

    static let surahs: [SurahMeta] = [
        SurahMeta(number: 1, name: "الفاتحة", ayahCount: 7, startPage: 1, isMeccan: true),
        SurahMeta(number: 2, name: "البقرة", ayahCount: 286, startPage: 2, isMeccan: false),
        SurahMeta(number: 3, name: "آل عمران", ayahCount: 200, startPage: 50, isMeccan: false),
        SurahMeta(number: 4, name: "النساء", ayahCount: 176, startPage: 77, isMeccan: false),
        SurahMeta(number: 5, name: "المائدة", ayahCount: 120, startPage: 106, isMeccan: false),
        SurahMeta(number: 6, name: "الأنعام", ayahCount: 165, startPage: 128, isMeccan: true),
        SurahMeta(number: 7, name: "الأعراف", ayahCount: 206, startPage: 151, isMeccan: true),
        SurahMeta(number: 8, name: "الأنفال", ayahCount: 75, startPage: 177, isMeccan: false),
        SurahMeta(number: 9, name: "التوبة", ayahCount: 129, startPage: 187, isMeccan: false),
        SurahMeta(number: 10, name: "يونس", ayahCount: 109, startPage: 208, isMeccan: true),
        SurahMeta(number: 11, name: "هود", ayahCount: 123, startPage: 221, isMeccan: true),
        SurahMeta(number: 12, name: "يوسف", ayahCount: 111, startPage: 235, isMeccan: true),
        SurahMeta(number: 13, name: "الرعد", ayahCount: 43, startPage: 249, isMeccan: false),
        SurahMeta(number: 14, name: "إبراهيم", ayahCount: 52, startPage: 255, isMeccan: true),
        SurahMeta(number: 15, name: "الحجر", ayahCount: 99, startPage: 262, isMeccan: true),
        SurahMeta(number: 16, name: "النحل", ayahCount: 128, startPage: 267, isMeccan: true),
        SurahMeta(number: 17, name: "الإسراء", ayahCount: 111, startPage: 282, isMeccan: true),
        SurahMeta(number: 18, name: "الكهف", ayahCount: 110, startPage: 293, isMeccan: true),
        SurahMeta(number: 19, name: "مريم", ayahCount: 98, startPage: 305, isMeccan: true),
        SurahMeta(number: 20, name: "طه", ayahCount: 135, startPage: 312, isMeccan: true),
        SurahMeta(number: 21, name: "الأنبياء", ayahCount: 112, startPage: 322, isMeccan: true),
        SurahMeta(number: 22, name: "الحج", ayahCount: 78, startPage: 332, isMeccan: false),
        SurahMeta(number: 23, name: "المؤمنون", ayahCount: 118, startPage: 342, isMeccan: true),
        SurahMeta(number: 24, name: "النور", ayahCount: 64, startPage: 350, isMeccan: false),
        SurahMeta(number: 25, name: "الفرقان", ayahCount: 77, startPage: 359, isMeccan: true),
        SurahMeta(number: 26, name: "الشعراء", ayahCount: 227, startPage: 367, isMeccan: true),
        SurahMeta(number: 27, name: "النمل", ayahCount: 93, startPage: 377, isMeccan: true),
        SurahMeta(number: 28, name: "القصص", ayahCount: 88, startPage: 385, isMeccan: true),
        SurahMeta(number: 29, name: "العنكبوت", ayahCount: 69, startPage: 396, isMeccan: true),
        SurahMeta(number: 30, name: "الروم", ayahCount: 60, startPage: 404, isMeccan: true),
        SurahMeta(number: 31, name: "لقمان", ayahCount: 34, startPage: 411, isMeccan: true),
        SurahMeta(number: 32, name: "السجدة", ayahCount: 30, startPage: 415, isMeccan: true),
        SurahMeta(number: 33, name: "الأحزاب", ayahCount: 73, startPage: 418, isMeccan: false),
        SurahMeta(number: 34, name: "سبأ", ayahCount: 54, startPage: 428, isMeccan: true),
        SurahMeta(number: 35, name: "فاطر", ayahCount: 45, startPage: 434, isMeccan: true),
        SurahMeta(number: 36, name: "يس", ayahCount: 83, startPage: 440, isMeccan: true),
        SurahMeta(number: 37, name: "الصافات", ayahCount: 182, startPage: 446, isMeccan: true),
        SurahMeta(number: 38, name: "ص", ayahCount: 88, startPage: 453, isMeccan: true),
        SurahMeta(number: 39, name: "الزمر", ayahCount: 75, startPage: 458, isMeccan: true),
        SurahMeta(number: 40, name: "غافر", ayahCount: 85, startPage: 467, isMeccan: true),
        SurahMeta(number: 41, name: "فصلت", ayahCount: 54, startPage: 477, isMeccan: true),
        SurahMeta(number: 42, name: "الشورى", ayahCount: 53, startPage: 483, isMeccan: true),
        SurahMeta(number: 43, name: "الزخرف", ayahCount: 89, startPage: 489, isMeccan: true),
        SurahMeta(number: 44, name: "الدخان", ayahCount: 59, startPage: 496, isMeccan: true),
        SurahMeta(number: 45, name: "الجاثية", ayahCount: 37, startPage: 499, isMeccan: true),
        SurahMeta(number: 46, name: "الأحقاف", ayahCount: 35, startPage: 502, isMeccan: true),
        SurahMeta(number: 47, name: "محمد", ayahCount: 38, startPage: 507, isMeccan: false),
        SurahMeta(number: 48, name: "الفتح", ayahCount: 29, startPage: 511, isMeccan: false),
        SurahMeta(number: 49, name: "الحجرات", ayahCount: 18, startPage: 515, isMeccan: false),
        SurahMeta(number: 50, name: "ق", ayahCount: 45, startPage: 518, isMeccan: true),
        SurahMeta(number: 51, name: "الذاريات", ayahCount: 60, startPage: 520, isMeccan: true),
        SurahMeta(number: 52, name: "الطور", ayahCount: 49, startPage: 523, isMeccan: true),
        SurahMeta(number: 53, name: "النجم", ayahCount: 62, startPage: 526, isMeccan: true),
        SurahMeta(number: 54, name: "القمر", ayahCount: 55, startPage: 528, isMeccan: true),
        SurahMeta(number: 55, name: "الرحمن", ayahCount: 78, startPage: 531, isMeccan: false),
        SurahMeta(number: 56, name: "الواقعة", ayahCount: 96, startPage: 534, isMeccan: true),
        SurahMeta(number: 57, name: "الحديد", ayahCount: 29, startPage: 537, isMeccan: false),
        SurahMeta(number: 58, name: "المجادلة", ayahCount: 22, startPage: 542, isMeccan: false),
        SurahMeta(number: 59, name: "الحشر", ayahCount: 24, startPage: 545, isMeccan: false),
        SurahMeta(number: 60, name: "الممتحنة", ayahCount: 13, startPage: 549, isMeccan: false),
        SurahMeta(number: 61, name: "الصف", ayahCount: 14, startPage: 551, isMeccan: false),
        SurahMeta(number: 62, name: "الجمعة", ayahCount: 11, startPage: 553, isMeccan: false),
        SurahMeta(number: 63, name: "المنافقون", ayahCount: 11, startPage: 554, isMeccan: false),
        SurahMeta(number: 64, name: "التغابن", ayahCount: 18, startPage: 556, isMeccan: false),
        SurahMeta(number: 65, name: "الطلاق", ayahCount: 12, startPage: 558, isMeccan: false),
        SurahMeta(number: 66, name: "التحريم", ayahCount: 12, startPage: 560, isMeccan: false),
        SurahMeta(number: 67, name: "الملك", ayahCount: 30, startPage: 562, isMeccan: true),
        SurahMeta(number: 68, name: "القلم", ayahCount: 52, startPage: 564, isMeccan: true),
        SurahMeta(number: 69, name: "الحاقة", ayahCount: 52, startPage: 566, isMeccan: true),
        SurahMeta(number: 70, name: "المعارج", ayahCount: 44, startPage: 568, isMeccan: true),
        SurahMeta(number: 71, name: "نوح", ayahCount: 28, startPage: 570, isMeccan: true),
        SurahMeta(number: 72, name: "الجن", ayahCount: 28, startPage: 572, isMeccan: true),
        SurahMeta(number: 73, name: "المزمل", ayahCount: 20, startPage: 574, isMeccan: true),
        SurahMeta(number: 74, name: "المدثر", ayahCount: 56, startPage: 575, isMeccan: true),
        SurahMeta(number: 75, name: "القيامة", ayahCount: 40, startPage: 577, isMeccan: true),
        SurahMeta(number: 76, name: "الإنسان", ayahCount: 31, startPage: 578, isMeccan: false),
        SurahMeta(number: 77, name: "المرسلات", ayahCount: 50, startPage: 580, isMeccan: true),
        SurahMeta(number: 78, name: "النبأ", ayahCount: 40, startPage: 582, isMeccan: true),
        SurahMeta(number: 79, name: "النازعات", ayahCount: 46, startPage: 583, isMeccan: true),
        SurahMeta(number: 80, name: "عبس", ayahCount: 42, startPage: 585, isMeccan: true),
        SurahMeta(number: 81, name: "التكوير", ayahCount: 29, startPage: 586, isMeccan: true),
        SurahMeta(number: 82, name: "الانفطار", ayahCount: 19, startPage: 587, isMeccan: true),
        SurahMeta(number: 83, name: "المطففين", ayahCount: 36, startPage: 587, isMeccan: true),
        SurahMeta(number: 84, name: "الانشقاق", ayahCount: 25, startPage: 589, isMeccan: true),
        SurahMeta(number: 85, name: "البروج", ayahCount: 22, startPage: 590, isMeccan: true),
        SurahMeta(number: 86, name: "الطارق", ayahCount: 17, startPage: 591, isMeccan: true),
        SurahMeta(number: 87, name: "الأعلى", ayahCount: 19, startPage: 591, isMeccan: true),
        SurahMeta(number: 88, name: "الغاشية", ayahCount: 26, startPage: 592, isMeccan: true),
        SurahMeta(number: 89, name: "الفجر", ayahCount: 30, startPage: 593, isMeccan: true),
        SurahMeta(number: 90, name: "البلد", ayahCount: 20, startPage: 594, isMeccan: true),
        SurahMeta(number: 91, name: "الشمس", ayahCount: 15, startPage: 595, isMeccan: true),
        SurahMeta(number: 92, name: "الليل", ayahCount: 21, startPage: 595, isMeccan: true),
        SurahMeta(number: 93, name: "الضحى", ayahCount: 11, startPage: 596, isMeccan: true),
        SurahMeta(number: 94, name: "الشرح", ayahCount: 8, startPage: 596, isMeccan: true),
        SurahMeta(number: 95, name: "التين", ayahCount: 8, startPage: 597, isMeccan: true),
        SurahMeta(number: 96, name: "العلق", ayahCount: 19, startPage: 597, isMeccan: true),
        SurahMeta(number: 97, name: "القدر", ayahCount: 5, startPage: 598, isMeccan: true),
        SurahMeta(number: 98, name: "البينة", ayahCount: 8, startPage: 598, isMeccan: false),
        SurahMeta(number: 99, name: "الزلزلة", ayahCount: 8, startPage: 599, isMeccan: false),
        SurahMeta(number: 100, name: "العاديات", ayahCount: 11, startPage: 599, isMeccan: true),
        SurahMeta(number: 101, name: "القارعة", ayahCount: 11, startPage: 600, isMeccan: true),
        SurahMeta(number: 102, name: "التكاثر", ayahCount: 8, startPage: 600, isMeccan: true),
        SurahMeta(number: 103, name: "العصر", ayahCount: 3, startPage: 601, isMeccan: true),
        SurahMeta(number: 104, name: "الهمزة", ayahCount: 9, startPage: 601, isMeccan: true),
        SurahMeta(number: 105, name: "الفيل", ayahCount: 5, startPage: 601, isMeccan: true),
        SurahMeta(number: 106, name: "قريش", ayahCount: 4, startPage: 602, isMeccan: true),
        SurahMeta(number: 107, name: "الماعون", ayahCount: 7, startPage: 602, isMeccan: true),
        SurahMeta(number: 108, name: "الكوثر", ayahCount: 3, startPage: 602, isMeccan: true),
        SurahMeta(number: 109, name: "الكافرون", ayahCount: 6, startPage: 603, isMeccan: true),
        SurahMeta(number: 110, name: "النصر", ayahCount: 3, startPage: 603, isMeccan: false),
        SurahMeta(number: 111, name: "المسد", ayahCount: 5, startPage: 603, isMeccan: true),
        SurahMeta(number: 112, name: "الإخلاص", ayahCount: 4, startPage: 604, isMeccan: true),
        SurahMeta(number: 113, name: "الفلق", ayahCount: 5, startPage: 604, isMeccan: true),
        SurahMeta(number: 114, name: "الناس", ayahCount: 6, startPage: 604, isMeccan: true)
    ]

    func preloadInBackground() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.ensureBundledLoaded()
        }
    }

    private func ensureBundledLoaded() {
        lock.lock()
        if didLoadBundled {
            lock.unlock()
            return
        }
        didLoadBundled = true
        lock.unlock()

        guard let url = Bundle.main.url(forResource: "quran_uthmani_full", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dObj = root["data"] as? [String: Any],
              let surahsArr = dObj["surahs"] as? [[String: Any]] else {
            return
        }

        var byPage: [Int: [QuranAyahItem]] = [:]
        var flat: [QuranAyahItem] = []
        flat.reserveCapacity(6250)

        for s in surahsArr {
            let sNum = s["number"] as? Int ?? 1
            let sName = s["name"] as? String ?? ""
            let ayahs = s["ayahs"] as? [[String: Any]] ?? []
            for a in ayahs {
                let nInSurah = a["numberInSurah"] as? Int ?? 1
                let txt = (a["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let juz = a["juz"] as? Int ?? 1
                let page = a["page"] as? Int ?? 1
                let item = QuranAyahItem(
                    surahNumber: sNum,
                    surahName: sName,
                    numberInSurah: nInSurah,
                    text: txt,
                    juz: juz,
                    page: page,
                    normalizedText: Self.normalizeArabic(txt)
                )
                flat.append(item)
                byPage[page, default: []].append(item)
            }
        }

        var built: [Int: QuranPageContent] = [:]
        for (p, list) in byPage where !list.isEmpty {
            built[p] = QuranPageContent(pageNumber: p, juzNumber: list[0].juz, primarySurahName: list[0].surahName, ayahs: list)
        }

        lock.lock()
        self.pagesCache = built
        self.allAyahs = flat
        lock.unlock()
    }

    func getPageImmediate(_ rawPage: Int) -> QuranPageContent? {
        let p = max(1, min(604, rawPage))
        lock.lock()
        defer { lock.unlock() }
        return pagesCache[p]
    }

    func loadPage(_ rawPage: Int) async -> QuranPageContent? {
        let page = max(1, min(604, rawPage))
        if let cached = getPageImmediate(page) { return cached }
        ensureBundledLoaded()
        if let cached = getPageImmediate(page) { return cached }

        // Fallback online fetch from Al Quran Cloud API
        guard let url = URL(string: "https://api.alquran.cloud/v1/page/\(page)/quran-uthmani") else { return nil }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dObj = root["data"] as? [String: Any],
                  let arr = dObj["ayahs"] as? [[String: Any]] else { return nil }
            var list: [QuranAyahItem] = []
            for a in arr {
                let sObj = a["surah"] as? [String: Any]
                let sNum = sObj?["number"] as? Int ?? 1
                let sName = sObj?["name"] as? String ?? ""
                let nInSurah = a["numberInSurah"] as? Int ?? 1
                let txt = (a["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let juz = a["juz"] as? Int ?? 1
                list.append(QuranAyahItem(surahNumber: sNum, surahName: sName, numberInSurah: nInSurah, text: txt, juz: juz, page: page, normalizedText: Self.normalizeArabic(txt)))
            }
            guard !list.isEmpty else { return nil }
            let content = QuranPageContent(pageNumber: page, juzNumber: list[0].juz, primarySurahName: list[0].surahName, ayahs: list)
            lock.lock()
            pagesCache[page] = content
            lock.unlock()
            return content
        } catch {
            return nil
        }
    }

    func searchAyahs(query: String) async -> [QuranAyahItem] {
        let norm = Self.normalizeArabic(query)
        guard norm.count >= 2 else { return [] }
        ensureBundledLoaded()
        lock.lock()
        let copy = allAyahs
        lock.unlock()
        var results: [QuranAyahItem] = []
        for a in copy {
            if a.normalizedText.contains(norm) {
                results.append(a)
                if results.count >= 35 { break }
            }
        }
        return results
    }

    static func normalizeArabic(_ input: String) -> String {
        var out = ""
        out.reserveCapacity(input.count)
        for scalar in input.unicodeScalars {
            let v = scalar.value
            if (v >= 0x064B && v <= 0x065F) || (v >= 0x0610 && v <= 0x061A) || (v >= 0x06D6 && v <= 0x06ED) || v == 0x0640 || v == 0x0670 {
                continue
            }
            switch scalar {
            case "أ", "إ", "آ", "ٱ": out.append("ا")
            case "ة": out.append("ه")
            case "ى", "ئ": out.append("ي")
            case "ؤ": out.append("و")
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    static func toArabicDigits(_ num: Int) -> String {
        let map: [Character: Character] = ["0":"٠","1":"١","2":"٢","3":"٣","4":"٤","5":"٥","6":"٦","7":"٧","8":"٨","9":"٩"]
        return String(String(num).map { map[$0] ?? $0 })
    }
}
