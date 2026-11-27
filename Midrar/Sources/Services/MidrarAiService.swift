import Foundation

struct MidrarAiReply: Codable {
    var allowed: Bool
    var rateLimited: Bool
    var cached: Bool
    var provider: String
    var reply: String
    var practicalTip: String
    var verse: String
    var verseRef: String
    var dua: String
    var suggestedDhikr: String
    var suggestedCount: Int

    enum CodingKeys: String, CodingKey {
        case allowed
        case rateLimited = "rate_limited"
        case cached
        case provider
        case reply
        case practicalTip = "practical_tip"
        case verse
        case verseRef = "verse_ref"
        case dua
        case suggestedDhikr = "suggested_dhikr"
        case suggestedCount = "suggested_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        allowed = (try? c.decode(Bool.self, forKey: .allowed)) ?? true
        rateLimited = (try? c.decode(Bool.self, forKey: .rateLimited)) ?? false
        cached = (try? c.decode(Bool.self, forKey: .cached)) ?? false
        provider = (try? c.decode(String.self, forKey: .provider)) ?? ""
        reply = ((try? c.decode(String.self, forKey: .reply)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        practicalTip = ((try? c.decode(String.self, forKey: .practicalTip)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        verse = ((try? c.decode(String.self, forKey: .verse)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        verseRef = ((try? c.decode(String.self, forKey: .verseRef)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        dua = ((try? c.decode(String.self, forKey: .dua)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        suggestedDhikr = ((try? c.decode(String.self, forKey: .suggestedDhikr)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        suggestedCount = (try? c.decode(Int.self, forKey: .suggestedCount)) ?? 33
    }
}

final class MidrarAiService {
    static let shared = MidrarAiService()
    private let endpoint = "\(SupabaseService.projectURL)/functions/v1/midrar-ai"
    private let cachePrefix = "midrar_ai_cache_v1_"

    private init() {}

    func askHeartHelper(deviceId: String, message: String) async throws -> MidrarAiReply {
        let payload: [String: Any] = [
            "mode": "heart",
            "device_id": deviceId.isEmpty ? "ios" : deviceId,
            "message": message
        ]
        return try await postRequest(payload: payload, cacheKey: nil)
    }

    func askAyahReflection(deviceId: String, ayahKey: String, surahName: String, ayahNumber: Int, ayahText: String) async throws -> MidrarAiReply {
        let ck = "ayah_\(ayahKey)"
        if let cached = loadCached(key: ck) {
            return cached
        }
        let payload: [String: Any] = [
            "mode": "ayah",
            "device_id": deviceId.isEmpty ? "ios" : deviceId,
            "ayah_key": ayahKey,
            "surah_name": surahName,
            "ayah_number": "\(ayahNumber)",
            "ayah_text": ayahText
        ]
        return try await postRequest(payload: payload, cacheKey: ck)
    }

    func askWeeklyCoach(deviceId: String, weekKey: String, stats: [String: Any]) async throws -> MidrarAiReply {
        let ck = "weekly_\(weekKey)"
        if let cached = loadCached(key: ck) {
            return cached
        }
        let payload: [String: Any] = [
            "mode": "weekly",
            "device_id": deviceId.isEmpty ? "ios" : deviceId,
            "stats": stats
        ]
        return try await postRequest(payload: payload, cacheKey: ck)
    }

    private func postRequest(payload: [String: Any], cacheKey: String?) async throws -> MidrarAiReply {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 22
        let key = SupabaseService.publishableKey.trimmingCharacters(in: .whitespacesAndNewlines)
        req.setValue(key, forHTTPHeaderField: "apikey")
        if key.hasPrefix("eyJ") {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 500
        let decoded = try JSONDecoder().decode(MidrarAiReply.self, from: data)
        if (200..<300).contains(status), let ck = cacheKey, decoded.allowed, !decoded.reply.isEmpty {
            saveCached(key: ck, data: data)
        }
        return decoded
    }

    private func loadCached(key: String) -> MidrarAiReply? {
        guard let data = UserDefaults.standard.data(forKey: cachePrefix + key) else { return nil }
        return try? JSONDecoder().decode(MidrarAiReply.self, from: data)
    }

    private func saveCached(key: String, data: Data) {
        UserDefaults.standard.set(data, forKey: cachePrefix + key)
    }
}
