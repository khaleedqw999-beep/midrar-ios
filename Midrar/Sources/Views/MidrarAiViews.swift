import SwiftUI

struct HeartHelperView: View {
    @EnvironmentObject var store: MidrarStore
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var reply: MidrarAiReply? = nil
    @State private var errorMsg: String? = nil

    private let quickMoods = [
        "أحس بضيق وهم",
        "متوتر قبل اختبار أو عمل",
        "فتور وكسل عن العبادة",
        "دعاء للوالدين",
        "طلب الرزق والتوفيق",
        "شكر وامتنان لله"
    ]

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("✨ مُعين القلب")
                        .font(.system(size: 21, weight: .heavy))
                    Text("مساعد روحاني للذكر ومواساة القلب فقط")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("إغلاق") { dismiss() }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(store.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickMoods, id: \.self) { mood in
                        Button {
                            inputText = mood
                            sendQuery()
                        } label: {
                            Text(mood)
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.cardSurface))
                                .overlay(Capsule().stroke(Color.cardBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }

            HStack(spacing: 8) {
                TextField("اكتب ما يشغل قلبك بكلمات بسيطة...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardSurface))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
                    .submitLabel(.send)
                    .onSubmit { sendQuery() }

                Button {
                    sendQuery()
                } label: {
                    Text("إرسال")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 16).fill(store.accentColor))
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(store.accentColor)
                            Text("جاري تحضير رسالة دافئة لقلبك...")
                                .font(.system(size: 13.5))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 13.5))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(24)
                    } else if let res = reply {
                        AiResultCardsView(reply: res, onApplyDhikr: { dhikr in
                            let item = DhikrItem(
                                id: "ai_\(UUID().uuidString)",
                                arabicText: dhikr,
                                shortTitle: String(dhikr.prefix(24)),
                                virtue: "ذكر مقترح من مُعين القلب",
                                effectType: 0,
                                isCustom: true
                            )
                            store.state.customDhikrs.append(item)
                            store.state.activeDhikrId = item.id
                            store.saveImmediate()
                            dismiss()
                        })
                    } else {
                        Text("اختر حالتك من الأزرار بالأعلى أو اكتب ما في قلبك، وسيقترح لك «مُعين مِدْرَار» آية ودعاءً وذكراً يمكنك البدء به فوراً في الواحة 🌿")
                            .font(.system(size: 13.5))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 36)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

            Text("«مُعين مِدْرَار» مساعد روحاني للذكر والقرآن فقط ولا يُصدر فتاوى شرعية")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.bottom, 14)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func sendQuery() {
        let q = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isLoading = true
        errorMsg = nil
        Task {
            do {
                let res = try await MidrarAiService.shared.askHeartHelper(deviceId: store.state.userId, message: q)
                await MainActor.run {
                    self.reply = res
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMsg = "يرجى التأكد من الاتصال بالإنترنت والمحاولة مرة أخرى 🌿"
                    self.isLoading = false
                }
            }
        }
    }
}

struct AyahReflectionView: View {
    @EnvironmentObject var store: MidrarStore
    @Environment(\.dismiss) private var dismiss

    let ayah: QuranAyahItem
    @State private var isLoading: Bool = true
    @State private var reply: MidrarAiReply? = nil
    @State private var errorMsg: String? = nil

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("📖 تأمّل الآية")
                        .font(.system(size: 20, weight: .heavy))
                    Text("سورة \(ayah.surahName) · آية \(QuranRepository.toArabicDigits(ayah.numberInSurah))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("إغلاق") { dismiss() }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(store.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Text("﴿ \(ayah.text) ﴾")
                .font(.system(size: 17.5, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(store.accentColor.opacity(0.35), lineWidth: 1.2))
                .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView().tint(store.accentColor)
                            Text("جاري جلب التأمّل المبسّط للآية...")
                                .font(.system(size: 13.5))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 30)
                    } else if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 13.5))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(24)
                    } else if let res = reply {
                        AiResultCardsView(reply: res, onApplyDhikr: nil)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .task {
            let key = "\(ayah.surahNumber):\(ayah.numberInSurah)"
            do {
                let res = try await MidrarAiService.shared.askAyahReflection(
                    deviceId: store.state.userId,
                    ayahKey: key,
                    surahName: ayah.surahName,
                    ayahNumber: ayah.numberInSurah,
                    ayahText: ayah.text
                )
                await MainActor.run {
                    self.reply = res
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMsg = "يرجى الاتصال بالإنترنت لجلب تأمّل هذه الآية لأول مرة 🌿"
                    self.isLoading = false
                }
            }
        }
    }
}

struct WeeklyCoachView: View {
    @EnvironmentObject var store: MidrarStore
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading: Bool = true
    @State private var reply: MidrarAiReply? = nil
    @State private var errorMsg: String? = nil

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("📊 مرشد العبادات الأسبوعي")
                        .font(.system(size: 20, weight: .heavy))
                    Text("قراءة إيمانية مشجّعة لتقدّمك هذا الأسبوع")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("إغلاق") { dismiss() }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(store.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView().tint(store.accentColor)
                            Text("جاري تحليل وردك الأسبوعي...")
                                .font(.system(size: 13.5))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 13.5))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(24)
                    } else if let res = reply {
                        AiResultCardsView(reply: res, onApplyDhikr: nil)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .task {
            let cal = Calendar.current
            let wk = "\(cal.component(.yearForWeekOfYear, from: Date()))-W\(cal.component(.weekOfYear, from: Date()))"
            let stats: [String: Any] = [
                "total_istighfar": store.state.totalIstighfar,
                "current_streak_days": store.state.currentStreak,
                "today_istighfar": store.state.todayIstighfar,
                "quran_pages_today": store.state.settings.quranPagesReadToday
            ]
            do {
                let res = try await MidrarAiService.shared.askWeeklyCoach(deviceId: store.state.userId, weekKey: wk, stats: stats)
                await MainActor.run {
                    self.reply = res
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMsg = "يرجى الاتصال بالإنترنت لجلب ملخص الأسبوع 🌿"
                    self.isLoading = false
                }
            }
        }
    }
}

private struct AiResultCardsView: View {
    @EnvironmentObject var store: MidrarStore
    let reply: MidrarAiReply
    let onApplyDhikr: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 11) {
            if !reply.reply.isEmpty {
                cardBox(title: reply.allowed ? "🌿 رسالة لقلبك" : "تنبيه لطيف", text: reply.reply, highlight: reply.allowed)
            }
            if reply.allowed {
                if !reply.verse.isEmpty {
                    let vText = "﴿ \(reply.verse) ﴾" + (reply.verseRef.isEmpty ? "" : "\n— \(reply.verseRef)")
                    cardBox(title: "📖 آية تطمئن بها", text: vText, highlight: true)
                }
                if !reply.practicalTip.isEmpty {
                    cardBox(title: "✨ خطوة عملية اليوم", text: reply.practicalTip, highlight: false)
                }
                if !reply.dua.isEmpty {
                    cardBox(title: "🤲 دعاء مقترح", text: reply.dua, highlight: false)
                }
                if !reply.suggestedDhikr.isEmpty, let apply = onApplyDhikr {
                    Button {
                        apply(reply.suggestedDhikr)
                    } label: {
                        Text("🌿 ابدأ «\(reply.suggestedDhikr)» في الواحة الآن")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(store.accentColor))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func cardBox(title: String, text: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(store.accentColor)
            Text(text)
                .font(.system(size: 14.5))
                .lineSpacing(5)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(15)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(highlight ? store.accentColor.opacity(0.4) : Color.cardBorder, lineWidth: 1.2)
        )
    }
}
