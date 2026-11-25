import SwiftUI
import UIKit

private struct TapRipple: Identifiable {
    let id = UUID()
    let point: CGPoint
    let createdAt: Date = Date()
}

struct OasisView: View {
    @EnvironmentObject var store: MidrarStore
    @StateObject private var voiceService = VoiceDhikrService()

    @State private var isIdleTranslucent = false
    @State private var idleWorkItem: DispatchWorkItem?
    @State private var showDhikrPicker = false
    @State private var showIntentionSheet = false
    @State private var isEyesFreeMode = false
    @State private var tapPulse = false
    @State private var counterBounce = false
    @State private var ripples: [TapRipple] = []
    @State private var lastRainTrigger: Date = .distantPast

    private var isFriday: Bool {
        Calendar.current.component(.weekday, from: Date()) == 6
    }

    private var pinnedDua: DuaItem? {
        store.state.duas.first(where: { $0.isPinned })
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. Living 598-Frame Oasis Scene — strictly clamped to viewport width so it NEVER overflows iPhone 16 Pro Max
                OasisPlateImage(frameName: store.currentFrameName)
                    .frame(width: geo.size.width, height: geo.size.height + 84)
                    .clipped()
                    .offset(y: -26)
                    .scaleEffect(tapPulse ? 1.016 : 1.0)
                    .animation(.spring(response: 0.34, dampingFraction: 0.72), value: tapPulse)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // 2. Smooth 24-Hour Sky Atmosphere + Bottom Legibility Scrim
                VStack(spacing: 0) {
                    skyAtmosphereOverlay
                        .frame(height: geo.size.height * 0.44)
                    Spacer()
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.26)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 170)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // 3. 120Hz Atmospheric Canvas: Soft Falling Rain on Tap + Drifting Fireflies + Expanding Water Ripples
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    Canvas { context, size in
                        let now = timeline.date
                        let t = now.timeIntervalSinceReferenceDate

                        // A. Soft Golden Fireflies / Light Motes
                        let moteCount = 12
                        for i in 0..<moteCount {
                            let seed = Double(i) * 1.6180339
                            let px = (sin(t * (0.22 + Double(i % 4) * 0.05) + seed * 4.0) * 0.42 + 0.5) * size.width
                            let py = (cos(t * (0.16 + Double(i % 3) * 0.04) + seed * 3.1) * 0.28 + 0.52) * size.height
                            let glowAlpha = 0.16 + 0.22 * (0.5 + 0.5 * sin(t * 1.4 + seed * 5.0))
                            let radius = CGFloat(2.2 + Double(i % 3) * 1.1)
                            let rect = CGRect(x: px - radius, y: py - radius, width: radius * 2, height: radius * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(Color(hex: "F5E6C8").opacity(glowAlpha)))
                        }

                        // B. Gentle Rain Streaks triggered on Dhikr tap
                        let rainElapsed = now.timeIntervalSince(lastRainTrigger)
                        if rainElapsed < 1.8 {
                            let rainFade = max(0.0, 1.0 - (rainElapsed / 1.8))
                            let dropCount = 22
                            for i in 0..<dropCount {
                                let seed = Double(i) * 2.39996
                                let xNorm = fmod(abs(sin(seed * 12.9898) * 43758.5453), 1.0)
                                let speed = 420.0 + Double(i % 5) * 95.0
                                let yPos = fmod(t * speed + seed * 240.0, size.height + 120.0) - 60.0
                                let xPos = xNorm * size.width
                                var p = Path()
                                p.move(to: CGPoint(x: xPos, y: yPos))
                                p.addLine(to: CGPoint(x: xPos - 3.0, y: yPos + 22.0))
                                context.stroke(
                                    p,
                                    with: .color(Color.white.opacity(0.32 * rainFade)),
                                    style: StrokeStyle(lineWidth: 1.35, lineCap: .round)
                                )
                            }
                        }

                        // C. Concentric Spatial Tap Ripples
                        for ripple in ripples {
                            let dt = now.timeIntervalSince(ripple.createdAt)
                            guard dt >= 0 && dt < 0.72 else { continue }
                            let prog = dt / 0.72
                            let ease = 1.0 - pow(1.0 - prog, 3.0)
                            let r1 = CGFloat(20.0 + ease * 110.0)
                            let alpha = (1.0 - prog) * 0.55
                            let rect1 = CGRect(x: ripple.point.x - r1, y: ripple.point.y - r1, width: r1 * 2, height: r1 * 2)
                            context.stroke(
                                Path(ellipseIn: rect1),
                                with: .color(store.accentColor.opacity(alpha)),
                                style: StrokeStyle(lineWidth: 2.2 * (1.0 - prog) + 0.6)
                            )
                            let r2 = CGFloat(10.0 + ease * 62.0)
                            let rect2 = CGRect(x: ripple.point.x - r2, y: ripple.point.y - r2, width: r2 * 2, height: r2 * 2)
                            context.stroke(
                                Path(ellipseIn: rect2),
                                with: .color(Color.white.opacity(alpha * 0.7)),
                                style: StrokeStyle(lineWidth: 1.2)
                            )
                        }
                    }
                }
                .allowsHitTesting(false)

                // 4. Full-Screen Spatial Tap Target
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                handleTap(at: value.location)
                            }
                    )

                // 5. Top HUD + Glass Counter Card + Bottom Intention Pill (Balanced for iPhone 16 Pro Max)
                VStack(spacing: 12) {
                    // Top Status Row
                    HStack(spacing: 8) {
                        hudBadge(icon: "flame.fill", text: "\(store.state.currentStreak) يوم", color: Color(hex: "C68A2E"))
                        hudBadge(icon: "leaf.fill", text: "\(store.state.todayCount) / \(store.state.dailyGoal)", color: store.accentColor)
                        Spacer()

                        iconCircleButton(systemName: store.settingsSoundIcon) {
                            store.state.settings.soundEnabled.toggle()
                            HapticsAndAudio.shared.soundEnabled = store.state.settings.soundEnabled
                            store.saveImmediate()
                            wakeChrome()
                        }
                        iconCircleButton(
                            systemName: voiceService.isListening ? "mic.fill" : "mic",
                            tint: voiceService.isListening ? store.accentColor : .primary
                        ) {
                            voiceService.onDhikrDetected = {
                                handleTap(at: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.56))
                            }
                            voiceService.toggle()
                            wakeChrome()
                        }
                        iconCircleButton(systemName: "moon.stars") {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isEyesFreeMode = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Floating Glass Counter & Active Dhikr Card
                    VStack(spacing: 10) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("\(store.state.totalIstighfar)")
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .contentTransition(.numericText())
                                        .scaleEffect(counterBounce ? 1.07 : 1.0)
                                        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: counterBounce)
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(store.accentColor)
                                }
                                Text(stageLabel)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                showDhikrPicker = true
                                wakeChrome()
                            } label: {
                                HStack(spacing: 6) {
                                    Text(store.activeDhikr.shortTitle)
                                        .font(.system(size: 13.5, weight: .bold))
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    Capsule()
                                        .fill(store.accentColor)
                                        .shadow(color: store.accentColor.opacity(0.28), radius: 6, x: 0, y: 3)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Daily Goal Progress Bar
                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(store.accentColor)
                                    .frame(width: max(6, barGeo.size.width * store.dailyGoalProgress), height: 5)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.dailyGoalProgress)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.45), lineWidth: 0.9)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
                    )
                    .padding(.horizontal, 20)

                    if let msg = voiceService.statusMessage {
                        Text(msg)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(store.accentColor.opacity(0.92)))
                            .transition(.opacity.combined(with: .scale))
                    }

                    if isFriday && store.activeDhikr.id != "salat_nabi" {
                        Button {
                            store.state.activeDhikrId = "salat_nabi"
                            store.saveImmediate()
                            handleTap(at: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.56))
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .bold))
                                Text("جمعة مباركة — اضغط للصلاة على النبي ﷺ")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "9A661F"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(.ultraThinMaterial))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Bottom Intention Pill cleanly above bottom dock
                    Button {
                        showIntentionSheet = true
                        wakeChrome()
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "hands.sparkles.fill")
                                .font(.system(size: 13))
                                .foregroundColor(store.accentColor)
                            Text(pinnedDua.map { "نيتي: \($0.text)" } ?? "انوي دعوة لهذه الجلسة")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 0.8))
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 16)
                }
                .opacity(isIdleTranslucent ? 0.78 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isIdleTranslucent)

                // 6. Eyes-Free OLED Serenity Overlay
                if isEyesFreeMode {
                    ZStack {
                        Color.black.ignoresSafeArea()
                            .onTapGesture {
                                handleTap(at: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.5))
                            }
                        VStack {
                            Spacer()
                            Text("\(store.state.totalIstighfar)")
                                .font(.system(size: 76, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                                .foregroundColor(.white.opacity(0.26))
                            Text(store.activeDhikr.shortTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.22))
                                .padding(.top, 4)
                            Spacer()
                            Text("انقر في أي مكان للاستغفار\nاضغط مرتين هنا للعودة")
                                .font(.system(size: 13.5, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.36))
                                .padding(.bottom, 36)
                                .onTapGesture(count: 2) {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isEyesFreeMode = false
                                    }
                                }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onAppear { wakeChrome() }
        .onDisappear { voiceService.stop() }
        .sheet(isPresented: $showDhikrPicker) {
            DhikrPickerSheetView()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showIntentionSheet) {
            NavigationStack {
                ImpactView()
                    .environmentObject(store)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("تم") { showIntentionSheet = false }
                        }
                    }
            }
        }
    }

    private var stageLabel: String {
        if store.isWilted { return "واحتك تشتاق للغيث.. اسقِها الآن" }
        let s = store.currentStage
        if s <= 60 { return "أرض تنتظر الغيث" }
        if s <= 180 { return "بداية الإنبات والأغصان" }
        if s <= 350 { return "نمو الشجرة واخضرارها" }
        if s < MidrarStore.maxStage { return "واحة مزهرة تنمو بذكرك" }
        return "واحة مكتملة الثمار"
    }

    private var skyAtmosphereOverlay: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight = (hour >= 19 || hour < 5)
        let isSunset = (hour >= 17 && hour < 19) || (hour >= 5 && hour < 7)
        return LinearGradient(
            colors: isNight
                ? [Color(hex: "081326").opacity(0.54), Color.clear]
                : (isSunset ? [Color(hex: "B85D32").opacity(0.22), Color.clear] : [Color.black.opacity(0.08), Color.clear]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func handleTap(at location: CGPoint) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.72)) {
            store.recordDhikrTap()
        }
        wakeChrome()
        tapPulse = true
        counterBounce = true
        lastRainTrigger = Date()

        let now = Date()
        ripples = ripples.filter { now.timeIntervalSince($0.createdAt) < 0.75 }
        ripples.append(TapRipple(point: location))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            tapPulse = false
            counterBounce = false
        }
    }

    private func wakeChrome() {
        isIdleTranslucent = false
        idleWorkItem?.cancel()
        let item = DispatchWorkItem { isIdleTranslucent = true }
        idleWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: item)
    }

    private func hudBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.42), lineWidth: 0.8))
        )
    }

    private func iconCircleButton(systemName: String, tint: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(Circle().stroke(Color.white.opacity(0.42), lineWidth: 0.8))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct DhikrPickerSheetView: View {
    @EnvironmentObject var store: MidrarStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("اختر صيغة الذكر")
                    .font(.system(size: 20, weight: .heavy))
                Spacer()
                Button("إغلاق") { dismiss() }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(store.accentColor)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(store.allDhikrs) { item in
                        let isSelected = (store.activeDhikr.id == item.id)
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                store.state.activeDhikrId = item.id
                                store.saveImmediate()
                            }
                            HapticsAndAudio.shared.gentleTick()
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.arabicText)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    if !item.virtue.isEmpty {
                                        Text(item.virtue)
                                            .font(.system(size: 12.5))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(isSelected ? store.accentColor : .secondary.opacity(0.4))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(isSelected ? store.accentColor.opacity(0.10) : Color.cardSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(isSelected ? store.accentColor : Color.cardBorder, lineWidth: isSelected ? 1.5 : 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
    }
}

private extension MidrarStore {
    var settingsSoundIcon: String {
        state.settings.soundEnabled ? "speaker.wave.2" : "speaker.slash"
    }
}

private struct OasisPlateImage: View {
    let frameName: String

    var body: some View {
        if let url = Bundle.main.url(forResource: frameName, withExtension: "webp", subdirectory: "cinema")
            ?? Bundle.main.url(forResource: frameName, withExtension: "webp"),
           let uiImg = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImg)
                .resizable()
                .scaledToFill()
        } else {
            Color(hex: "F6F8F7")
        }
    }
}
