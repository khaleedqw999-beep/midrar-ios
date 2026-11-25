import SwiftUI

struct WorshipTrackerView: View {
    @EnvironmentObject var store: MidrarStore
    @State private var subTab: Int = 0 // 0=المتابعة, 1=مكتبة الأذكار
    @State private var selectedDateKey: String = MidrarStore.todayDateKey()
    @State private var showMorningAdhkar = false
    @State private var showEveningAdhkar = false
    @State private var showAddCustomDhikr = false
    @State private var customDhikrTitle = ""

    private var weekDays: [(key: String, shortName: String, dayNum: String)] {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun .. 7=Sat
        let offsetFromMon = (weekday == 1) ? 6 : (weekday - 2)
        let monday = cal.date(byAdding: .day, value: -offsetFromMon, to: now) ?? now
        let names = ["إثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت", "أحد"]
        let dfKey = DateFormatter()
        dfKey.locale = Locale(identifier: "en_US_POSIX")
        dfKey.dateFormat = "yyyy-MM-dd"
        let dfDay = DateFormatter()
        dfDay.locale = Locale(identifier: "en_US_POSIX")
        dfDay.dateFormat = "d"

        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: monday) ?? now
            return (dfKey.string(from: d), names[i], dfDay.string(from: d))
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Text("متابعة العبادات")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.top, 8)

                // Clean Underlined 2-Tab Switcher
                HStack(spacing: 0) {
                    subTabButton(title: "المتابعة", idx: 0)
                    subTabButton(title: "مكتبة الأذكار", idx: 1)
                }
                .overlay(alignment: .bottom) { Divider() }

                if subTab == 0 {
                    trackerContent
                } else {
                    dhikrLibraryContent
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showMorningAdhkar) {
            AdhkarSessionSheetView(isMorning: true) {
                store.recordDhikrTap()
            } onComplete: {
                store.setHabitDone(dateKey: selectedDateKey, habitKey: "adhkar_morning", done: true)
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showEveningAdhkar) {
            AdhkarSessionSheetView(isMorning: false) {
                store.recordDhikrTap()
            } onComplete: {
                store.setHabitDone(dateKey: selectedDateKey, habitKey: "adhkar_evening", done: true)
            }
            .environmentObject(store)
        }
        .alert("إضافة ذكر خاص", isPresented: $showAddCustomDhikr) {
            TextField("مثال: سبحان الله وبحمده", text: $customDhikrTitle)
            Button("إضافة") {
                let t = customDhikrTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty {
                    let item = DhikrItem(id: "custom_\(UUID().uuidString.prefix(6))", arabicText: t, shortTitle: String(t.prefix(18)), virtue: "ذكر خاص بك", effectType: 0, isCustom: true)
                    store.state.customDhikrs.append(item)
                    store.state.activeDhikrId = item.id
                    store.saveImmediate()
                    customDhikrTitle = ""
                }
            }
            Button("إلغاء", role: .cancel) {}
        }
    }

    private func subTabButton(title: String, idx: Int) -> some View {
        let active = (subTab == idx)
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                subTab = idx
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: active ? .bold : .medium))
                    .foregroundColor(active ? store.accentColor : .secondary)
                Rectangle()
                    .fill(active ? store.accentColor : Color.clear)
                    .frame(height: 2.5)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var trackerContent: some View {
        let pct = store.dailyHabitScore(dateKey: selectedDateKey)
        let prayers = PrayerTimeCalculator.computeForToday(cityName: store.state.settings.userCity)
        let prayerDefs: [(key: String, name: String, icon: String, time: String)] = [
            ("fajr", "الفجر", "sunrise", PrayerTimeCalculator.formatTime12h(prayers.fajrMin)),
            ("dhuhr", "الظهر", "sun.max", PrayerTimeCalculator.formatTime12h(prayers.dhuhrMin)),
            ("asr", "العصر", "cloud.sun", PrayerTimeCalculator.formatTime12h(prayers.asrMin)),
            ("maghrib", "المغرب", "sunset", PrayerTimeCalculator.formatTime12h(prayers.maghribMin)),
            ("isha", "العشاء", "moon", PrayerTimeCalculator.formatTime12h(prayers.ishaMin))
        ]

        return VStack(alignment: .leading, spacing: 18) {
            // Dark Obsidian Date + Completion Ring + 7-Day Strip
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(arabicDayName(for: selectedDateKey))
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(hijriString(for: selectedDateKey))  •  \(selectedDateKey)")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: CGFloat(pct) / 100.0)
                            .stroke(store.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(pct)%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 48, height: 48)
                }

                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.key) { slot in
                        let slotPct = store.dailyHabitScore(dateKey: slot.key)
                        let isSel = (slot.key == selectedDateKey)
                        Button {
                            selectedDateKey = slot.key
                            HapticsAndAudio.shared.gentleTick()
                        } label: {
                            VStack(spacing: 6) {
                                Text(slot.shortName)
                                    .font(.system(size: 10.5))
                                    .foregroundColor(isSel ? .white : .white.opacity(0.55))
                                Circle()
                                    .fill(slotPct >= 70 ? store.accentColor : Color.white.opacity(0.14))
                                    .overlay(Circle().stroke(slotPct > 0 && slotPct < 70 ? store.accentColor : Color.clear, lineWidth: 2))
                                    .frame(width: 18, height: 18)
                                Text(slot.dayNum)
                                    .font(.system(size: 11, weight: isSel ? .bold : .regular))
                                    .foregroundColor(isSel ? store.accentColor : .white.opacity(0.65))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(hex: "151E24")))

            // Section 1: 5 Prayers
            HStack {
                Text("الصلوات").font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(store.countDone(dateKey: selectedDateKey, keys: ["fajr", "dhuhr", "asr", "maghrib", "isha"]))/5")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(prayerDefs, id: \.key) { p in
                    let done = store.isHabitDone(dateKey: selectedDateKey, habitKey: p.key)
                    Button {
                        store.toggleHabit(dateKey: selectedDateKey, habitKey: p.key)
                    } label: {
                        VStack(spacing: 6) {
                            Text(p.name)
                                .font(.system(size: 11.5, weight: done ? .bold : .medium))
                                .foregroundColor(done ? store.accentColor : .secondary)
                            Image(systemName: p.icon)
                                .font(.system(size: 16))
                                .foregroundColor(done ? store.accentColor : .secondary)
                            Text(p.time)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardSurface)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(done ? store.accentColor : Color.cardBorder, lineWidth: done ? 1.6 : 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Section 2: Adhkar
            Text("الأذكار").font(.system(size: 16, weight: .bold))
            VStack(spacing: 8) {
                habitRow(key: "adhkar_morning", title: "أذكار الصباح", subtitle: "افتح الورد المتسلسل أو اضغط للتعليم", icon: "sunrise") {
                    if !store.isHabitDone(dateKey: selectedDateKey, habitKey: "adhkar_morning") {
                        showMorningAdhkar = true
                    } else {
                        store.toggleHabit(dateKey: selectedDateKey, habitKey: "adhkar_morning")
                    }
                }
                habitRow(key: "adhkar_evening", title: "أذكار المساء", subtitle: "افتح الورد المتسلسل أو اضغط للتعليم", icon: "sunset") {
                    if !store.isHabitDone(dateKey: selectedDateKey, habitKey: "adhkar_evening") {
                        showEveningAdhkar = true
                    } else {
                        store.toggleHabit(dateKey: selectedDateKey, habitKey: "adhkar_evening")
                    }
                }
                habitRow(key: "adhkar_sleep", title: "أذكار النوم", subtitle: "تحصين المسلم قبل النوم حتى الفجر", icon: "bed.double")
            }

            // Section 3: Quran
            Text("القرآن الكريم").font(.system(size: 16, weight: .bold))
            habitRow(key: "quran_daily", title: "قراءة القرآن", subtitle: "ورد يومي من القرآن الكريم", icon: "book")

            // Section 4: Daily Worship
            HStack {
                Text("عبادات يومية").font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(store.isHabitDone(dateKey: selectedDateKey, habitKey: "duha") ? 1 : 0)/1")
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }
            habitRow(key: "duha", title: "صلاة الضحى", subtitle: "من ٢ إلى ٨ ركعات بعد شروق الشمس", icon: "sun.max")

            // Section 5: Sunnah Rawatib
            HStack {
                Text("سنن رواتب").font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(store.countDone(dateKey: selectedDateKey, keys: ["sunnah_fajr", "sunnah_dhuhr_pre", "sunnah_dhuhr_post", "sunnah_maghrib", "sunnah_isha", "qiyam", "witr"]))/7")
                    .font(.system(size: 13)).foregroundColor(.secondary)
            }
            VStack(spacing: 8) {
                habitRow(key: "sunnah_fajr", title: "سنة الفجر", subtitle: "ركعتان قبل صلاة الفجر", icon: "building.columns")
                habitRow(key: "sunnah_dhuhr_pre", title: "سنة الظهر القبلية", subtitle: "٤ ركعات قبل صلاة الظهر", icon: "building.columns")
                habitRow(key: "sunnah_dhuhr_post", title: "سنة الظهر البعدية", subtitle: "ركعتان بعد صلاة الظهر", icon: "building.columns")
                habitRow(key: "sunnah_maghrib", title: "سنة المغرب", subtitle: "ركعتان بعد صلاة المغرب", icon: "building.columns")
                habitRow(key: "sunnah_isha", title: "سنة العشاء", subtitle: "ركعتان بعد صلاة العشاء", icon: "building.columns")
                habitRow(key: "qiyam", title: "قيام الليل", subtitle: "من بعد صلاة العشاء حتى طلوع الفجر", icon: "moon.zzz")
                habitRow(key: "witr", title: "صلاة الوتر", subtitle: "ركعة أو ثلاث أو خمس أو سبع أو إحدى عشرة", icon: "hands.sparkles")
            }

            // Section 6: Fasting
            HStack(spacing: 8) {
                Text("الصيام").font(.system(size: 16, weight: .bold))
                Text(fastingBadge(for: selectedDateKey))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(store.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.cardSurface))
            }
            habitRow(key: "fasting", title: "صمت اليوم", subtitle: "صيام التطوع أو الأيام البيض", icon: "sparkles")

            // Score Breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("% كيف يُحسب الإنجاز؟")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.secondary)
                Text("الصلوات 50%  •  الأذكار 10%  •  القرآن 10%\nعبادات يومية 10%  •  النوافل 10%  •  الصيام 10%")
                    .font(.system(size: 11.5))
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.cardBorder)))
        }
    }

    private var dhikrLibraryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button { showMorningAdhkar = true } label: {
                    Text("أذكار الصباح")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Capsule().fill(store.accentColor))
                }
                Button { showEveningAdhkar = true } label: {
                    Text("أذكار المساء")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Capsule().fill(Color.cardSurface).overlay(Capsule().stroke(Color.cardBorder)))
                }
            }

            Button { showAddCustomDhikr = true } label: {
                Text("+ إضافة ذكر أو وِرد خاص بك")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 42)
                    .background(Capsule().fill(store.accentColor))
            }

            ForEach(store.allDhikrs) { item in
                let isSelected = (item.id == store.state.activeDhikrId)
                Button {
                    store.state.activeDhikrId = item.id
                    store.saveImmediate()
                    HapticsAndAudio.shared.gentleTick()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.arabicText)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isSelected ? store.accentColor : .primary)
                            Text(item.virtue)
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(store.state.dhikrLifetimeCounts[item.id] ?? 0)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(store.accentColor)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.cardSurface)
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isSelected ? store.accentColor : Color.cardBorder, lineWidth: isSelected ? 1.6 : 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func habitRow(key: String, title: String, subtitle: String, icon: String, customAction: (() -> Void)? = nil) -> some View {
        let done = store.isHabitDone(dateKey: selectedDateKey, habitKey: key)
        return Button {
            if let customAction {
                customAction()
            } else {
                store.toggleHabit(dateKey: selectedDateKey, habitKey: key)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(done ? store.accentColor : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(done ? store.accentColor : .primary)
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(done ? store.accentColor : Color.clear)
                        .overlay(Circle().stroke(done ? store.accentColor : Color.secondary.opacity(0.45), lineWidth: 1.5))
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardSurface)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(done ? store.accentColor : Color.cardBorder, lineWidth: done ? 1.5 : 1))
            )
        }
        .buttonStyle(.plain)
    }

    private func arabicDayName(for key: String) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        guard let d = df.date(from: key) else { return "اليوم" }
        let out = DateFormatter()
        out.locale = Locale(identifier: "ar")
        out.dateFormat = "EEEE"
        return out.string(from: d)
    }

    private func hijriString(for key: String) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        guard let d = df.date(from: key) else { return "" }
        let hijri = Calendar(identifier: .islamicUmmAlQura)
        let comps = hijri.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", comps.year ?? 1448, comps.month ?? 1, comps.day ?? 1)
    }

    private func fastingBadge(for key: String) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        guard let d = df.date(from: key) else { return "صيام التطوع" }
        let hDay = Calendar(identifier: .islamicUmmAlQura).component(.day, from: d)
        if hDay >= 13 && hDay <= 15 { return "الأيام البيض" }
        let dow = Calendar(identifier: .gregorian).component(.weekday, from: d)
        if dow == 2 || dow == 5 { return "سنة الإثنين والخميس" }
        return "صيام التطوع"
    }
}

struct AdhkarSessionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: MidrarStore
    let isMorning: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var index = 0
    @State private var remaining = 1

    private var entries: [AdhkarEntry] {
        isMorning ? AdhkarEntry.morning : AdhkarEntry.evening
    }

    var body: some View {
        let current = entries[min(index, entries.count - 1)]
        VStack(spacing: 18) {
            HStack {
                Text(isMorning ? "أذكار الصباح" : "أذكار المساء")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(store.accentColor)
                Spacer()
                Text("\(index + 1) / \(entries.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(index + 1), total: Double(entries.count))
                .tint(store.accentColor)

            Spacer()

            VStack(spacing: 16) {
                Text(current.text)
                    .font(.system(size: 19, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                Text(current.virtue)
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("\(remaining)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(store.accentColor)
                    .frame(width: 84, height: 84)
                    .background(Circle().fill(Color.appBackground).overlay(Circle().stroke(store.accentColor, lineWidth: 2)))
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.cardBorder)))
            .onTapGesture {
                onTap()
                if remaining > 1 {
                    remaining -= 1
                } else if index < entries.count - 1 {
                    index += 1
                    remaining = entries[index].targetCount
                } else {
                    onComplete()
                    dismiss()
                }
            }

            Text("انقر على البطاقة للذكر وسُقيا الواحة")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()

            Button("إغلاق") { dismiss() }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(24)
        .onAppear {
            remaining = entries.first?.targetCount ?? 1
        }
    }
}
