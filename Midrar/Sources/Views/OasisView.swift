import SwiftUI
import UIKit

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
    @State private var dropletPhase: CGFloat = 0
    @State private var showDroplet = false

    private var isFriday: Bool {
        Calendar.current.component(.weekday, from: Date()) == 6
    }

    private var pinnedDua: DuaItem? {
        store.state.duas.first(where: { $0.isPinned })
    }

    var body: some View {
        ZStack {
            // 1. Living 598-Frame Oasis Scene lifted upward (+26pt) above bottom intention pill
            OasisPlateImage(frameName: store.currentFrameName)
                .offset(y: -26)
                .scaleEffect(tapPulse ? 1.015 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.72), value: tapPulse)
                .ignoresSafeArea()

            // 2. Smooth 24-Hour Sky Atmosphere Overlay (Zero Blocky Artifacts)
            skyAtmosphereOverlay
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 3. Soft Rain Ripple on Tap
            if showDroplet {
                Circle()
                    .stroke(store.accentColor.opacity(0.45 * (1 - dropletPhase)), lineWidth: 2)
                    .frame(width: 60 + dropletPhase * 180, height: 60 + dropletPhase * 180)
                    .allowsHitTesting(false)
            }

            // 4. Full-Screen Tap Target
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    handleTap()
                }

            // 5. Top HUD + Counter Card (Never disappears; gently rests at 0.74 opacity when idle)
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    hudBadge(icon: "flame", text: "\(store.state.currentStreak) يوم", color: Color(hex: "C68A2E"))
                    hudBadge(icon: "leaf", text: "\(store.state.todayCount) / \(store.state.dailyGoal)", color: store.accentColor)
                    Spacer()

                    iconCircleButton(systemName: store.settingsSoundIcon) {
                        store.state.settings.soundEnabled.toggle()
                        HapticsAndAudio.shared.soundEnabled = store.state.settings.soundEnabled
                        store.saveImmediate()
                        wakeChrome()
                    }
                    iconCircleButton(systemName: voiceService.isListening ? "mic.fill" : "mic") {
                        voiceService.onDhikrDetected = { handleTap() }
                        voiceService.toggle()
                        wakeChrome()
                    }
                    iconCircleButton(systemName: "moon.stars") {
                        isEyesFreeMode = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                // Counter + Active Dhikr Card
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Text("\(store.state.totalIstighfar)")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .scaleEffect(counterBounce ? 1.08 : 1.0)
                            Image(systemName: "drop.fill")
                                .font(.system(size: 14))
                                .foregroundColor(store.accentColor)
                        }
                        Spacer()
                        Button {
                            showDhikrPicker = true
                            wakeChrome()
                        } label: {
                            HStack(spacing: 6) {
                                Text(store.activeDhikr.shortTitle)
                                    .font(.system(size: 13.5, weight: .bold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(store.accentColor))
                        }
                    }

                    Text(stageLabel)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.35)))
                )
                .padding(.horizontal, 16)

                if let msg = voiceService.statusMessage {
                    Text(msg)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(store.accentColor.opacity(0.92)))
                }

                if isFriday && store.activeDhikr.id != "salat_nabi" {
                    Button {
                        store.state.activeDhikrId = "salat_nabi"
                        store.saveImmediate()
                        handleTap()
                    } label: {
                        Text("جمعة مباركة — اضغط للصلاة على النبي ﷺ")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color(hex: "9A661F"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }
                }

                Spacer()

                // Bottom Intention Pill above anchored dock
                Button {
                    showIntentionSheet = true
                    wakeChrome()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hands.sparkles")
                            .font(.system(size: 13))
                            .foregroundColor(store.accentColor)
                        Text(pinnedDua.map { "نيتي: \($0.text)" } ?? "انوي دعوة لهذه الجلسة")
                            .font(.system(size: 12.5, weight: .semibold))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(.ultraThinMaterial))
                }
                .padding(.bottom, 86)
            }
            .opacity(isIdleTranslucent ? 0.74 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isIdleTranslucent)

            // 6. Eyes-Free OLED Serenity Overlay
            if isEyesFreeMode {
                ZStack {
                    Color.black.ignoresSafeArea()
                        .onTapGesture {
                            handleTap()
                        }
                    VStack {
                        Spacer()
                        Text("\(store.state.totalIstighfar)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.24))
                        Spacer()
                        Text("انقر في أي مكان للاستغفار\nاضغط مطولاً أو مرتين هنا للعودة")
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.32))
                            .padding(.bottom, 90)
                            .onTapGesture(count: 2) {
                                isEyesFreeMode = false
                            }
                    }
                }
            }
        }
        .onAppear { wakeChrome() }
        .onDisappear { voiceService.stop() }
        .confirmationDialog("اختر الذكر", isPresented: $showDhikrPicker, titleVisibility: .visible) {
            ForEach(store.allDhikrs) { item in
                Button(item.arabicText) {
                    store.state.activeDhikrId = item.id
                    store.saveImmediate()
                }
            }
            Button("إلغاء", role: .cancel) {}
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
                ? [Color(hex: "081326").opacity(0.55), Color.clear]
                : (isSunset ? [Color(hex: "B85D32").opacity(0.24), Color.clear] : [Color.clear, Color.clear]),
            startPoint: .top,
            endPoint: .center
        )
    }

    private func handleTap() {
        store.recordDhikrTap()
        wakeChrome()
        tapPulse = true
        counterBounce = true
        showDroplet = true
        dropletPhase = 0
        withAnimation(.easeOut(duration: 0.55)) {
            dropletPhase = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            tapPulse = false
            counterBounce = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            showDroplet = false
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
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(.ultraThinMaterial))
    }

    private func iconCircleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(.ultraThinMaterial))
        }
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
