import SwiftUI

struct WorshipTrackerView: View {
    @EnvironmentObject var store: MidrarStore
    @State private var activeSubTab: Int = 0 // 0=المتابعة, 1=المصحف والورد, 2=مكتبة الأذكار
    @State private var selectedDateKey: String = MidrarStore.todayDateKey()
    @State private var activeAdhkarMode: AdhkarSessionMode? = nil
    @State private var showQuranReader: Bool = false
    @State private var showQiblaCompass: Bool = false
    @State private var showHeartHelper: Bool = false
    @State private var showWeeklyCoach: Bool = false
    @State private var quranStartPage: Int = 1
    @State private var quranSearchQuery: String = ""
    @State private var ayahSearchResults: [QuranAyahItem] = []
    @State private var showAddCustomDhikr: Bool = false
    @State private var customDhikrText: String = ""

    private var activePrayers: DailyPrayers {
        PrayerTimeCalculator.getActivePrayers(settings: store.state.settings)
    }

    private var weekDates: [(dayShort: String, dayNum: Int, key: String)] {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let offsetToMonday = (weekday == 1) ? -6 : (2 - weekday)
        guard let monday = cal.date(byAdding: .day, value: offsetToMonday, to: now) else { return [] }
        let names = ["إثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت", "أحد"]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return (0..<7).compactMap { i in
            guard let d = cal.date(byAdding: .day, value: i, to: monday) else { return nil }
            return (names[i], cal.component(.day, from: d), df.string(from: d))
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Text("متابعة العبادات")
                    .font(.system(size: 22, weight: .heavy))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)

                // Clean 3-Segment Underlined Switcher (المتابعة | المصحف والورد | مكتبة الأذكار)
                HStack(spacing: 0) {
                    subTabButton(title: "المتابعة", idx: 0)
                    subTabButton(title: "المصحف والورد", idx: 1)
                    subTabButton(title: "مكتبة الأذكار", idx: 2)
                }
                .overlay(Divider(), alignment: .bottom)

                if activeSubTab == 0 {
                    trackerSection
                } else if activeSubTab == 1 {
                    quranAndWirdSection
                } else {
                    dhikrLibrarySection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .sheet(isPresented: Binding(
            get: { activeAdhkarMode != nil },
            set: { if !$0 { activeAdhkarMode = nil } }
        )) {
            if let mode = activeAdhkarMode {
                AdhkarSessionSheetView(mode: mode) {
                    store.setHabitDone(dateKey: selectedDateKey, habitKey: mode.habitKey, done: true)
                    HapticsAndAudio.shared.goalCompletedFeedback()
                }
                .environmentObject(store)
            }
        }
        .fullScreenCover(isPresented: $showQuranReader) {
            QuranReaderView(currentPage: quranStartPage)
                .environmentObject(store)
        }
        .sheet(isPresented: $showQiblaCompass) {
            QiblaCompassView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showHeartHelper) {
            HeartHelperView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showWeeklyCoach) {
            WeeklyCoachView()
                .environmentObject(store)
        }
        .alert("إضافة ذكر خاص", isPresented: $showAddCustomDhikr) {
            TextField("اكتب صيغة الذكر...", text: $customDhikrText)
            Button("حفظ") {
                let t = customDhikrText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty {
                    let item = DhikrItem(id: "custom_\(UUID().uuidString)", arabicText: t, shortTitle: String(t.prefix(24)), virtue: "ذكر خاص مضاف بيدك", effectType: 0, isCustom: true)
                    store.state.customDhikrs.append(item)
                    store.state.activeDhikrId = item.id
                    store.saveImmediate()
                    customDhikrText = ""
                }
            }
            Button("إلغاء", role: .cancel) { customDhikrText = "" }
        }
    }

    private func subTabButton(title: String, idx: Int) -> some View {
        let active = (activeSubTab == idx)
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                activeSubTab = idx
            }
            HapticsAndAudio.shared.gentleTick()
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13.5, weight: active ? .bold : .medium))
                    .foregroundColor(active ? store.accentColor : .secondary)
                    .lineLimit(1)
                Rectangle()
                    .fill(active ? store.accentColor : Color.clear)
                    .frame(height: 2.5)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sub-Tab 0: Worship Tracker (No Fasting, Sleep Adhkar Interactive)
    private var trackerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Midrar Spiritual AI Quick Bar (V5.6: مُعين القلب + مرشد الأسبوع)
            HStack(spacing: 10) {
                Button {
                    HapticsAndAudio.shared.gentleTick()
                    showHeartHelper = true
                } label: {
                    HStack(spacing: 6) {
                        Text("✨ مُعين القلب")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(store.accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(store.accentColor.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(store.accentColor.opacity(0.45), lineWidth: 1.2))
                }
                .buttonStyle(.plain)

                Button {
                    HapticsAndAudio.shared.gentleTick()
                    showWeeklyCoach = true
                } label: {
                    HStack(spacing: 6) {
                        Text("📊 مرشد الأسبوع")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardSurface))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Obsidian Date + Progress Ring + 7-Day Strip
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(arabicDayName(for: selectedDateKey))
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        Text("\(hijriString(for: selectedDateKey)) • \(selectedDateKey)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.68))
                    }
                    Spacer()
                    let pct = store.dailyHabitScore(dateKey: selectedDateKey)
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.14), lineWidth: 4.5)
                        Circle()
                            .trim(from: 0, to: CGFloat(pct) / 100.0)
                            .stroke(store.accentColor, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(pct)٪")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                }

                HStack(spacing: 4) {
                    ForEach(weekDates, id: \.key) { slot in
                        let selected = (slot.key == selectedDateKey)
                        let dayPct = store.dailyHabitScore(dateKey: slot.key)
                        Button {
                            selectedDateKey = slot.key
                            HapticsAndAudio.shared.gentleTick()
                        } label: {
                            VStack(spacing: 5) {
                                Text(slot.dayShort)
                                    .font(.system(size: 10, weight: selected ? .bold : .medium))
                                    .foregroundColor(selected ? .white : .white.opacity(0.55))
                                ZStack {
                                    Circle()
                                        .stroke(selected ? store.accentColor : Color.white.opacity(0.18), lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                    if dayPct >= 100 {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(store.accentColor)
                                    } else if dayPct > 0 {
                                        Circle().fill(store.accentColor).frame(width: 7, height: 7)
                                    }
                                }
                                Text("\(slot.dayNum)")
                                    .font(.system(size: 11, weight: selected ? .bold : .medium))
                                    .foregroundColor(selected ? .white : .white.opacity(0.65))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(selected ? Color.white.opacity(0.12) : Color.clear))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(hex: "141918")))

            // Live Next-Prayer Countdown + Qibla Compass Button
            TimelineView(.periodic(from: .now, by: 30)) { timeline in
                let nextInfo = nextPrayerInfo(at: timeline.date)
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(store.accentColor.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 17))
                            .foregroundColor(store.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("الصلاة القادمة: \(nextInfo.name)")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(.primary)
                        Text("متبقي \(nextInfo.remainingText) • \(store.state.settings.userCity)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(store.accentColor)
                    }
                    Spacer()
                    Button {
                        showQiblaCompass = true
                        HapticsAndAudio.shared.gentleTick()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "safari.fill")
                                .font(.system(size: 13))
                            Text("القبلة")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(store.accentColor))
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.cardSurface)
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.cardBorder))
                )
            }

            // 1. Five Daily Prayers
            let prayersDone = store.countDone(dateKey: selectedDateKey, keys: ["fajr", "dhuhr", "asr", "maghrib", "isha"])
            sectionHeader(title: "الصلوات — \(store.state.settings.userCity)", counter: "\(prayersDone)/5")

            let pItems: [(key: String, name: String, icon: String, min: Int)] = [
                ("fajr", "الفجر", "sunrise", activePrayers.fajrMin),
                ("dhuhr", "الظهر", "sun.max", activePrayers.dhuhrMin),
                ("asr", "العصر", "sun.haze", activePrayers.asrMin),
                ("maghrib", "المغرب", "sunset", activePrayers.maghribMin),
                ("isha", "العشاء", "moon.stars", activePrayers.ishaMin)
            ]
            HStack(spacing: 6) {
                ForEach(pItems, id: \.key) { item in
                    let done = store.isHabitDone(dateKey: selectedDateKey, habitKey: item.key)
                    Button {
                        store.toggleHabit(dateKey: selectedDateKey, habitKey: item.key)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: done ? "\(item.icon).fill" : item.icon)
                                .font(.system(size: 17))
                                .foregroundColor(done ? .white : .secondary)
                            Text(item.name)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(done ? .white : .primary)
                            Text(PrayerTimeCalculator.formatTime12h(item.min))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(done ? .white.opacity(0.9) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(done ? store.accentColor : Color.cardSurface)
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(done ? store.accentColor : Color.cardBorder))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // 2. Adhkar (Morning, Evening, AND Sleep all launch sequential session!)
            let adhkarDone = store.countDone(dateKey: selectedDateKey, keys: ["adhkar_morning", "adhkar_evening", "adhkar_sleep"])
            sectionHeader(title: "الأذكار", counter: "\(adhkarDone)/3")
            VStack(spacing: 8) {
                habitRow(key: "adhkar_morning", title: "أذكار الصباح", subtitle: "افتح الورد المتسلسل مع زر السابق والتالي", icon: "sunrise") {
                    activeAdhkarMode = .morning
                }
                habitRow(key: "adhkar_evening", title: "أذكار المساء", subtitle: "افتح الورد المتسلسل مع زر السابق والتالي", icon: "sunset") {
                    activeAdhkarMode = .evening
                }
                habitRow(key: "adhkar_sleep", title: "أذكار النوم", subtitle: "افتح أذكار النوم المتسلسلة قبل النوم", icon: "moon.zzz") {
                    activeAdhkarMode = .sleep
                }
            }

            // 3. Quran Daily Reading (Opens Mushaf directly)
            let qDone = store.isHabitDone(dateKey: selectedDateKey, habitKey: "quran_daily") ? 1 : 0
            sectionHeader(title: "القرآن الكريم", counter: "\(qDone)/1")
            habitRow(key: "quran_daily", title: "ورد القرآن اليومي", subtitle: "اضغط لفتح المصحف على صفحة \(QuranRepository.toArabicDigits(store.state.settings.quranCurrentPage))", icon: "book") {
                quranStartPage = store.state.settings.quranCurrentPage
                showQuranReader = true
            }

            // 4. Daily Worship
            let dDone = store.isHabitDone(dateKey: selectedDateKey, habitKey: "duha") ? 1 : 0
            sectionHeader(title: "عبادات يومية", counter: "\(dDone)/1")
            habitRow(key: "duha", title: "صلاة الضحى", subtitle: "ركعتان إلى ثمان ركعات بعد الشروق", icon: "sun.max")

            // 5. Sunnah Rawatib
            let sunnahKeys = ["sunnah_fajr", "sunnah_dhuhr_pre", "sunnah_dhuhr_post", "sunnah_maghrib", "sunnah_isha", "qiyam", "witr"]
            let sDone = store.countDone(dateKey: selectedDateKey, keys: sunnahKeys)
            sectionHeader(title: "سنن رواتب", counter: "\(sDone)/7")
            VStack(spacing: 8) {
                habitRow(key: "sunnah_fajr", title: "سنة الفجر", subtitle: "ركعتان قبل صلاة الفجر", icon: "sparkles")
                habitRow(key: "sunnah_dhuhr_pre", title: "سنة الظهر القبلية", subtitle: "٤ ركعات قبل صلاة الظهر", icon: "sparkles")
                habitRow(key: "sunnah_dhuhr_post", title: "سنة الظهر البعدية", subtitle: "ركعتان بعد صلاة الظهر", icon: "sparkles")
                habitRow(key: "sunnah_maghrib", title: "سنة المغرب", subtitle: "ركعتان بعد صلاة المغرب", icon: "sparkles")
                habitRow(key: "sunnah_isha", title: "سنة العشاء", subtitle: "ركعتان بعد صلاة العشاء", icon: "sparkles")
                habitRow(key: "qiyam", title: "قيام الليل", subtitle: "من بعد العشاء حتى الفجر", icon: "moon")
                habitRow(key: "witr", title: "صلاة الوتر", subtitle: "ركعة أو ثلاث أو أكثر", icon: "star")
            }

            // Rebalanced 100% Score Legend (No Fasting)
            VStack(alignment: .leading, spacing: 6) {
                Text("٪ كيف يُحسب الإنجاز اليومي؟")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.secondary)
                Text("الصلوات 50٪  •  الأذكار 15٪  •  القرآن 15٪\nعبادات يومية 10٪  •  النوافل 10٪")
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.cardBorder)))
        }
    }

    // MARK: - Sub-Tab 1: Integrated Offline Quran & Daily Wird Planner
    private var quranAndWirdSection: some View {
        let today = MidrarStore.todayDateKey()
        let readToday = store.state.settings.quranLastReadDate == today ? store.state.settings.quranPagesReadToday : 0
        let goal = max(1, store.state.settings.quranDailyPages)
        let khatmahDays = Int(ceil(604.0 / Double(goal)))
        let progress = min(1.0, Double(readToday) / Double(goal))

        return VStack(alignment: .leading, spacing: 14) {
            // Daily Wird Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("الوِرد اليومي من القرآن 📖")
                        .font(.system(size: 16.5, weight: .heavy))
                    Spacer()
                    Text("ختمة في \(QuranRepository.toArabicDigits(khatmahDays)) يوماً")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(store.accentColor)
                }

                Text("قرأت \(QuranRepository.toArabicDigits(readToday)) من \(QuranRepository.toArabicDigits(goal)) صفحات اليوم • الموضع الحالي: صفحة \(QuranRepository.toArabicDigits(store.state.settings.quranCurrentPage))")
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)

                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08)).frame(height: 6)
                        Capsule().fill(store.accentColor).frame(width: max(8, g.size.width * progress), height: 6)
                    }
                }
                .frame(height: 6)

                // Daily Pages Stepper
                HStack {
                    Text("عدد الصفحات يومياً")
                        .font(.system(size: 13.5, weight: .bold))
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            if store.state.settings.quranDailyPages > 1 {
                                store.state.settings.quranDailyPages -= 1
                                store.saveImmediate()
                                NotificationService.rescheduleAll(state: store.state)
                                HapticsAndAudio.shared.gentleTick()
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.appBackground))
                        }
                        .buttonStyle(.plain)

                        Text("\(QuranRepository.toArabicDigits(goal)) صفحات")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(store.accentColor)

                        Button {
                            if store.state.settings.quranDailyPages < 30 {
                                store.state.settings.quranDailyPages += 1
                                store.saveImmediate()
                                NotificationService.rescheduleAll(state: store.state)
                                HapticsAndAudio.shared.gentleTick()
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.appBackground))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().opacity(0.4)

                // Custom Notification Time + Toggle
                HStack {
                    Toggle("إشعار «ابدأ وردك اليومي»", isOn: Binding(
                        get: { store.state.settings.quranWirdReminderEnabled },
                        set: {
                            store.state.settings.quranWirdReminderEnabled = $0
                            store.saveImmediate()
                            NotificationService.rescheduleAll(state: store.state)
                        }
                    ))
                    .font(.system(size: 13.5, weight: .semibold))
                    .tint(store.accentColor)
                }

                if store.state.settings.quranWirdReminderEnabled {
                    DatePicker(
                        "وقت التذكير اليومي",
                        selection: Binding(
                            get: {
                                var comps = DateComponents()
                                comps.hour = store.state.settings.quranWirdHour
                                comps.minute = store.state.settings.quranWirdMinute
                                return Calendar.current.date(from: comps) ?? Date()
                            },
                            set: { newDate in
                                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                store.state.settings.quranWirdHour = c.hour ?? 21
                                store.state.settings.quranWirdMinute = c.minute ?? 0
                                store.saveImmediate()
                                NotificationService.rescheduleAll(state: store.state)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 13, weight: .medium))
                    .tint(store.accentColor)
                }

                Button {
                    quranStartPage = store.state.settings.quranCurrentPage
                    showQuranReader = true
                    HapticsAndAudio.shared.gentleTick()
                } label: {
                    Text("افتح المصحف وابدأ ورد اليوم (صفحة \(QuranRepository.toArabicDigits(store.state.settings.quranCurrentPage))) 📖")
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(store.accentColor))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.cardBorder)))

            // Search Bar (Surah Name, Full-Text Ayah, or Page 1..604)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("ابحث عن سورة أو آية (مثال: يا ايها الكافرون) أو صفحة...", text: $quranSearchQuery)
                    .font(.system(size: 13.5))
                    .onChange(of: quranSearchQuery) { newVal in
                        let q = newVal.trimmingCharacters(in: .whitespacesAndNewlines)
                        if q.count >= 2 && Int(q) == nil {
                            Task {
                                let res = await QuranRepository.shared.searchAyahs(query: q)
                                await MainActor.run { ayahSearchResults = res }
                            }
                        } else {
                            ayahSearchResults = []
                        }
                    }
                if !quranSearchQuery.isEmpty {
                    Button { quranSearchQuery = ""; ayahSearchResults = [] } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cardBorder)))

            // Direct Page Jump
            if let pNum = Int(quranSearchQuery.trimmingCharacters(in: .whitespaces)), pNum >= 1 && pNum <= 604 {
                Button {
                    quranStartPage = pNum
                    showQuranReader = true
                } label: {
                    Text("📖 الانتقال مباشرة إلى صفحة \(QuranRepository.toArabicDigits(pNum))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(store.accentColor))
                }
                .buttonStyle(.plain)
            }

            // Full-Text Ayah Search Matches
            if !ayahSearchResults.isEmpty {
                Text("✨ نتائج البحث في الآيات (\(QuranRepository.toArabicDigits(ayahSearchResults.count)))")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(store.accentColor)
                VStack(spacing: 8) {
                    ForEach(ayahSearchResults) { ayah in
                        Button {
                            quranStartPage = ayah.page
                            showQuranReader = true
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("﴿ \(ayah.text) ﴾")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                Text("\(ayah.surahName) • الآية \(QuranRepository.toArabicDigits(ayah.numberInSurah)) • صفحة \(QuranRepository.toArabicDigits(ayah.page))")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(store.accentColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.cardBorder)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 114-Surah Index
            Text("فهرس سور المصحف الشريف (١١٤ سورة)")
                .font(.system(size: 14.5, weight: .bold))
                .padding(.top, 4)

            let trimmed = quranSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            let filteredSurahs = QuranRepository.surahs.filter {
                trimmed.isEmpty || $0.name.contains(trimmed) || "\($0.number)" == trimmed
            }
            LazyVStack(spacing: 8) {
                ForEach(filteredSurahs) { s in
                    Button {
                        quranStartPage = s.startPage
                        showQuranReader = true
                        HapticsAndAudio.shared.gentleTick()
                    } label: {
                        HStack(spacing: 12) {
                            Text(QuranRepository.toArabicDigits(s.number))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(store.accentColor)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(store.accentColor.opacity(0.12)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("سورة \(s.name)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("\(s.isMeccan ? "مكية" : "مدنية") • \(QuranRepository.toArabicDigits(s.ayahCount)) آية")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("ص \(QuranRepository.toArabicDigits(s.startPage))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(store.accentColor)
                        }
                        .padding(13)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.cardBorder)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sub-Tab 2: Dhikr Library (Entire Card Click-to-Activate)
    private var dhikrLibrarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                showAddCustomDhikr = true
            } label: {
                Text("+ إضافة ذكر خاص بك")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Capsule().fill(store.accentColor))
            }
            .buttonStyle(.plain)

            ForEach(store.allDhikrs) { item in
                let isActive = (item.id == store.activeDhikr.id)
                let lifetime = store.state.dhikrLifetimeCounts[item.id] ?? 0
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        store.state.activeDhikrId = item.id
                        store.saveImmediate()
                    }
                    HapticsAndAudio.shared.gentleTick()
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.arabicText)
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(isActive ? .white : .primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if isActive {
                                Text("✓ مفعل")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(store.accentColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white))
                            }
                        }
                        Text(item.virtue)
                            .font(.system(size: 12))
                            .foregroundColor(isActive ? .white.opacity(0.86) : .secondary)
                            .multilineTextAlignment(.leading)
                        Text("الإجمالي: \(lifetime) مرة")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(isActive ? .white.opacity(0.92) : store.accentColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(isActive ? store.accentColor : Color.cardSurface)
                            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(isActive ? store.accentColor : Color.cardBorder))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionHeader(title: String, counter: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .heavy))
            Spacer()
            Text(counter)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }

    private func habitRow(key: String, title: String, subtitle: String, icon: String, customAction: (() -> Void)? = nil) -> some View {
        let done = store.isHabitDone(dateKey: selectedDateKey, habitKey: key)
        return Button {
            if let action = customAction, !done {
                action()
            } else {
                store.toggleHabit(dateKey: selectedDateKey, habitKey: key)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(done ? store.accentColor : .secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .bold))
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
                            .font(.system(size: 11, weight: .bold))
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

    private func nextPrayerInfo(at date: Date) -> (name: String, remainingText: String) {
        let cal = Calendar.current
        let nowMin = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        let list: [(String, Int)] = [
            ("الفجر", activePrayers.fajrMin),
            ("الظهر", activePrayers.dhuhrMin),
            ("العصر", activePrayers.asrMin),
            ("المغرب", activePrayers.maghribMin),
            ("العشاء", activePrayers.ishaMin)
        ]
        var targetName = "الفجر"
        var diffMin = (activePrayers.fajrMin + 1440) - nowMin
        for (name, pMin) in list {
            if pMin > nowMin {
                targetName = name
                diffMin = pMin - nowMin
                break
            }
        }
        let h = diffMin / 60
        let m = diffMin % 60
        let formatted = String(format: "%02d:%02d", h, m)
        return (targetName, formatted)
    }

    private func arabicDayName(for key: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        guard let d = df.date(from: key) else { return "اليوم" }
        let out = DateFormatter()
        out.locale = Locale(identifier: "ar")
        out.dateFormat = "EEEE"
        return out.string(from: d)
    }

    private func hijriString(for key: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let d = df.date(from: key) ?? Date()
        let hijri = Calendar(identifier: .islamicUmmAlQura)
        let comps = hijri.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d هـ", comps.year ?? 1448, comps.month ?? 1, comps.day ?? 1)
    }
}

struct AdhkarSessionSheetView: View {
    @EnvironmentObject var store: MidrarStore
    @Environment(\.dismiss) private var dismiss
    let mode: AdhkarSessionMode
    let onCompleted: () -> Void

    @State private var index: Int = 0
    @State private var remaining: Int = 1

    private var entries: [AdhkarEntry] { mode.entries }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text(mode.title)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundColor(store.accentColor)
                Spacer()
                Text("\(index + 1) / \(entries.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.cardSurface))
            }

            ProgressView(value: Double(index + 1), total: Double(entries.count))
                .tint(store.accentColor)

            Spacer(minLength: 8)

            let current = entries[min(index, entries.count - 1)]
            Button {
                store.recordDhikrTap()
                if remaining > 1 {
                    remaining -= 1
                } else {
                    advance()
                }
            } label: {
                VStack(spacing: 16) {
                    Text(current.text)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                    Text(current.virtue)
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("انقر للعدّ • المتبقي \(remaining)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(store.accentColor))
                }
                .frame(maxWidth: .infinity)
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.cardSurface)
                        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.cardBorder))
                )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            // Bottom Controls: Previous + Next + Close
            HStack(spacing: 10) {
                Button {
                    goToPrevious()
                } label: {
                    Text("→ السابق")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Capsule().fill(Color.cardSurface))
                }
                .buttonStyle(.plain)
                .disabled(index == 0)
                .opacity(index > 0 ? 1.0 : 0.38)

                Button {
                    advance()
                } label: {
                    Text("التالي ←")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(store.accentColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Capsule().fill(Color.cardSurface))
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text("إغلاق")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Capsule().fill(Color.cardSurface))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .background(Color.appBackground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            remaining = entries.first?.targetCount ?? 1
        }
    }

    private func goToPrevious() {
        guard index > 0 else { return }
        HapticsAndAudio.shared.gentleTick()
        withAnimation(.easeInOut(duration: 0.2)) {
            index -= 1
            remaining = entries[index].targetCount
        }
    }

    private func advance() {
        if index + 1 < entries.count {
            withAnimation(.easeInOut(duration: 0.2)) {
                index += 1
                remaining = entries[index].targetCount
            }
        } else {
            onCompleted()
            dismiss()
        }
    }
}
