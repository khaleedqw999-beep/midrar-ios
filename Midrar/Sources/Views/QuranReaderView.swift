import SwiftUI

struct QuranReaderView: View {
    @EnvironmentObject var store: MidrarStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State var currentPage: Int
    @State private var pageContent: QuranPageContent?
    @State private var isLoading: Bool = false
    @State private var errorMsg: String?
    @State private var slideOffset: CGFloat = 0
    @State private var wirdBannerToast: String?
    @State private var showAyahPicker: Bool = false
    @State private var selectedAyahForReflection: QuranAyahItem? = nil

    private var paperBackground: Color {
        colorScheme == .dark ? Color(hex: "0D120F") : Color(hex: "FBF8F1")
    }

    private var barSurface: Color {
        colorScheme == .dark ? Color(hex: "151D18") : Color(hex: "F2ECE0")
    }

    private var primaryInk: Color {
        colorScheme == .dark ? Color(hex: "F1F5F2") : Color(hex: "1E241F")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Solid Opaque Top Header Bar (Zero background bleed-through under Dynamic Island)
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("إغلاق")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(paperBackground))
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 2) {
                    Text(pageContent?.primarySurahName ?? "المصحف الشريف")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(primaryInk)
                        .lineLimit(1)
                    Text("الجزء \(QuranRepository.toArabicDigits(pageContent?.juzNumber ?? 1)) • صفحة \(QuranRepository.toArabicDigits(currentPage)) من ٦٠٤")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Button { adjustFont(-2) } label: {
                        Text("أ-")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(primaryInk)
                            .frame(width: 34, height: 32)
                            .background(Capsule().fill(paperBackground))
                    }
                    .buttonStyle(.plain)

                    Button { adjustFont(2) } label: {
                        Text("أ+")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(primaryInk)
                            .frame(width: 34, height: 32)
                            .background(Capsule().fill(paperBackground))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(barSurface.ignoresSafeArea(edges: .top))

            // Daily Wird Progress Strip + Ayah Reflection AI Button
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 11.5))
                Text(wirdStatusText)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                Spacer()
                Button {
                    showAyahPicker = true
                } label: {
                    Text("✨ تأمّل آية")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(store.accentColor))
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(store.accentColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(store.accentColor.opacity(0.08))
            .confirmationDialog("✨ اختر آية للتأمّل المبسّط", isPresented: $showAyahPicker, titleVisibility: .visible) {
                if let ayahs = pageContent?.ayahs {
                    ForEach(Array(ayahs.prefix(15).enumerated()), id: \.offset) { _, a in
                        Button("﴿\(QuranRepository.toArabicDigits(a.numberInSurah))﴾ \(String(a.text.prefix(42)))...") {
                            selectedAyahForReflection = a
                        }
                    }
                }
                Button("إلغاء", role: .cancel) {}
            }
            .sheet(isPresented: Binding(
                get: { selectedAyahForReflection != nil },
                set: { if !$0 { selectedAyahForReflection = nil } }
            )) {
                if let a = selectedAyahForReflection {
                    AyahReflectionView(ayah: a)
                        .environmentObject(store)
                }
            }

            // Main Swipeable Mushaf Reading Area
            ZStack {
                if isLoading {
                    ProgressView("جاري تحميل الصفحة...")
                        .tint(store.accentColor)
                } else if let err = errorMsg {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(err)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        Button("إعادة المحاولة") { load(page: currentPage, direction: 0) }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(store.accentColor))
                    }
                } else if let content = pageContent {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            Text(buildAttributedPage(content))
                                .font(.system(size: store.state.settings.quranFontSize, weight: .regular))
                                .foregroundColor(primaryInk)
                                .multilineTextAlignment(.center)
                                .lineSpacing(12)
                                .padding(.horizontal, 22)
                                .padding(.top, 16)
                                .padding(.bottom, 30)
                        }
                        .offset(x: slideOffset)
                    }
                }

                if let toast = wirdBannerToast {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(store.accentColor))
                            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
                            .padding(.bottom, 14)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(paperBackground)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 36, coordinateSpace: .local)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        guard abs(dx) > 55 && abs(dx) > abs(dy) * 1.3 else { return }
                        if dx > 0 {
                            turnPage(to: currentPage + 1, direction: 1)
                        } else {
                            turnPage(to: currentPage - 1, direction: -1)
                        }
                    }
            )

            // Bottom Navigation Bar
            HStack(spacing: 10) {
                Button {
                    turnPage(to: currentPage - 1, direction: -1)
                } label: {
                    Text("‹ السابقة")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(primaryInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(paperBackground))
                }
                .buttonStyle(.plain)
                .opacity(currentPage > 1 ? 1.0 : 0.35)

                Button {
                    markPageCompleted()
                } label: {
                    Text("أتممت الصفحة ✓")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(store.accentColor))
                }
                .buttonStyle(.plain)

                Button {
                    turnPage(to: currentPage + 1, direction: 1)
                } label: {
                    Text("التالية ›")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(primaryInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(paperBackground))
                }
                .buttonStyle(.plain)
                .opacity(currentPage < 604 ? 1.0 : 0.35)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(barSurface.ignoresSafeArea(edges: .bottom))
        }
        .background(paperBackground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            load(page: currentPage, direction: 0)
        }
    }

    private var wirdStatusText: String {
        let today = MidrarStore.todayDateKey()
        let read = store.state.settings.quranLastReadDate == today ? store.state.settings.quranPagesReadToday : 0
        let goal = max(1, store.state.settings.quranDailyPages)
        if read >= goal {
            return "✓ أتممت وردك اليومي (\(QuranRepository.toArabicDigits(read)) / \(QuranRepository.toArabicDigits(goal))) • اسحب للتقليب"
        }
        return "ورد اليوم: \(QuranRepository.toArabicDigits(read)) من \(QuranRepository.toArabicDigits(goal)) صفحات • اسحب يميناً أو يساراً للتقليب"
    }

    private func turnPage(to target: Int, direction: CGFloat) {
        guard target >= 1 && target <= 604 else { return }
        HapticsAndAudio.shared.gentleTick()
        load(page: target, direction: direction)
    }

    private func load(page: Int, direction: CGFloat) {
        let clamped = max(1, min(604, page))
        currentPage = clamped
        store.state.settings.quranCurrentPage = clamped
        store.saveImmediate()
        errorMsg = nil

        if let immediate = QuranRepository.shared.getPageImmediate(clamped) {
            pageContent = immediate
            isLoading = false
            animateSlide(direction)
            return
        }

        isLoading = true
        Task {
            let loaded = await QuranRepository.shared.loadPage(clamped)
            await MainActor.run {
                isLoading = false
                if let loaded = loaded {
                    pageContent = loaded
                    animateSlide(direction)
                } else {
                    errorMsg = "تعذر تحميل الصفحة الآن. تأكد من الاتصال بالإنترنت."
                }
            }
        }
    }

    private func animateSlide(_ direction: CGFloat) {
        guard direction != 0 else { return }
        slideOffset = direction * -28
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            slideOffset = 0
        }
    }

    private func markPageCompleted() {
        let today = MidrarStore.todayDateKey()
        if store.state.settings.quranLastReadDate != today {
            store.state.settings.quranLastReadDate = today
            store.state.settings.quranPagesReadToday = 0
        }
        store.state.settings.quranPagesReadToday += 1
        let goal = max(1, store.state.settings.quranDailyPages)
        let justCompleted = (store.state.settings.quranPagesReadToday == goal)
        if store.state.settings.quranPagesReadToday >= goal {
            store.setHabitDone(dateKey: today, habitKey: "quran_daily", done: true)
        }
        let nextPage = currentPage < 604 ? currentPage + 1 : 1
        store.state.settings.quranCurrentPage = nextPage
        store.saveImmediate()

        if justCompleted {
            HapticsAndAudio.shared.goalCompletedFeedback()
            showToast("تقبل الله! أتممت وردك اليومي من القرآن الكريم 📖✨")
        } else {
            HapticsAndAudio.shared.mediumPulse()
            showToast("تم حفظ الصفحة (\(store.state.settings.quranPagesReadToday) / \(goal) من ورد اليوم)")
        }
        load(page: nextPage, direction: 1)
    }

    private func showToast(_ msg: String) {
        withAnimation { wirdBannerToast = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation { wirdBannerToast = nil }
        }
    }

    private func adjustFont(_ delta: CGFloat) {
        let next = max(16, min(34, store.state.settings.quranFontSize + delta))
        store.state.settings.quranFontSize = next
        store.saveImmediate()
        HapticsAndAudio.shared.gentleTick()
    }

    private func buildAttributedPage(_ content: QuranPageContent) -> AttributedString {
        var result = AttributedString()
        var lastSurah = -1
        for a in content.ayahs {
            if a.surahNumber != lastSurah && a.numberInSurah == 1 {
                if !result.characters.isEmpty { result.append(AttributedString("\n\n")) }
                var hdr = AttributedString("۞ \(a.surahName) ۞\n")
                hdr.foregroundColor = store.accentColor
                hdr.font = .system(size: max(16, store.state.settings.quranFontSize - 2), weight: .bold)
                result.append(hdr)
                if a.surahNumber != 1 && a.surahNumber != 9 {
                    let basmala = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
                    if !a.text.hasPrefix(basmala) {
                        result.append(AttributedString("\(basmala)\n"))
                    }
                }
            }
            lastSurah = a.surahNumber
            result.append(AttributedString("\(a.text) "))
            var numStr = AttributedString("﴿\(QuranRepository.toArabicDigits(a.numberInSurah))﴾ ")
            numStr.foregroundColor = store.accentColor
            result.append(numStr)
        }
        return result
    }
}
