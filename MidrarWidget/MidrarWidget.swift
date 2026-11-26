import WidgetKit
import SwiftUI

struct MidrarWidgetEntry: TimelineEntry {
    let date: Date
    let dhikrText: String
    let subtitle: String
}

struct MidrarWidgetProvider: TimelineProvider {
    private let dhikrs: [(text: String, sub: String)] = [
        ("أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ", "يُرْسِلِ السَّمَاءَ عَلَيْكُم مِّدْرَارًا"),
        ("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ", "حبيبتان إلى الرحمن"),
        ("اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ", "صلى الله عليه بها عشراً"),
        ("لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", "كنز من كنوز الجنة"),
        ("لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ", "دعوة ذي النون")
    ]

    func placeholder(in context: Context) -> MidrarWidgetEntry {
        MidrarWidgetEntry(date: Date(), dhikrText: dhikrs[0].text, subtitle: dhikrs[0].sub)
    }

    func getSnapshot(in context: Context, completion: @escaping (MidrarWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MidrarWidgetEntry>) -> Void) {
        var entries: [MidrarWidgetEntry] = []
        let now = Date()
        for hourOffset in 0..<5 {
            if let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now) {
                let item = dhikrs[hourOffset % dhikrs.count]
                entries.append(MidrarWidgetEntry(date: entryDate, dhikrText: item.text, subtitle: item.sub))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct MidrarWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: MidrarWidgetEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                    Text("مِدْرَار")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(entry.dhikrText)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
            }
            .environment(\.layoutDirection, .rightToLeft)

        case .accessoryInline:
            Label("مِدْرَار: أستغفر الله العظيم", systemImage: "drop.fill")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("مدرار")
                        .font(.system(size: 9, weight: .bold))
                }
            }

        default:
            // Home Screen (systemSmall & systemMedium)
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.29, green: 0.40, blue: 0.25), Color(red: 0.16, green: 0.24, blue: 0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.89, green: 0.75, blue: 0.54))
                        Text("مِدْرَار • ذِكر الشاشة")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.89, green: 0.75, blue: 0.54))
                        Spacer()
                    }
                    Spacer(minLength: 2)
                    Text(entry.dhikrText)
                        .font(.system(size: family == .systemSmall ? 14 : 17, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    Text(entry.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.78))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(14)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

@main
struct MidrarWidget: Widget {
    let kind: String = "MidrarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MidrarWidgetProvider()) { entry in
            MidrarWidgetView(entry: entry)
        }
        .configurationDisplayName("مِدْرَار — أذكار الشاشة")
        .description("يعرض أذكار الاستغفار والتسبيح على الشاشة الرئيسية وشاشة القفل.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}
