import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject var store: MidrarStore
    @ObservedObject private var locService = LocationPrayerService.shared
    @State private var showEditProfile = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Editorial Header
                VStack(alignment: .leading, spacing: 3) {
                    Text("ملفي وإعداداتي")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.primary)
                    Text("خصّص تجربتك وهويتك البصرية في مدرار")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)

                // Hero Profile Card
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [store.accentColor.opacity(0.26), store.accentColor.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(store.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        let medal = store.state.completedCyclesCount > 0 ? " 🏅\(store.state.completedCyclesCount)" : ""
                        Text((store.state.userName.isEmpty ? "أهلاً بك في مدرار" : store.state.userName) + medal)
                            .font(.system(size: 17, weight: .bold))
                        Text(store.state.userAge > 0 ? "العمر \(store.state.userAge) • \(store.isFemale ? "أنثى" : "ذكر")" : "اضغط لتخصيص ملفك")
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        showEditProfile = true
                        HapticsAndAudio.shared.gentleTick()
                    } label: {
                        Text("تعديل")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(store.accentColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(store.accentColor.opacity(0.12))
                                    .overlay(Capsule().stroke(store.accentColor.opacity(0.25), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(cardBackground)

                // Stats Trio Card
                HStack(spacing: 0) {
                    statBox(value: "\(store.state.totalIstighfar)", label: "إجمالي الذكر", icon: "drop.fill")
                    Divider().frame(height: 36).opacity(0.4)
                    statBox(value: "\(store.state.currentStreak)", label: "سلسلة الأيام", icon: "flame.fill")
                    Divider().frame(height: 36).opacity(0.4)
                    statBox(value: "\(store.currentStage)", label: "مستوى الواحة", icon: "leaf.fill")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 10)
                .background(cardBackground)

                // Identity & Theme Card (Tactile Circular Swatches + Segmented Appearance)
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        iconBadge("paintpalette.fill", color: store.accentColor)
                        Text("هوية التطبيق والمظهر")
                            .font(.system(size: 15, weight: .bold))
                    }

                    HStack(spacing: 10) {
                        ForEach([AccentPalette.olive, .blue, .rose, .sand], id: \.self) { palette in
                            let selected = store.state.settings.accentTheme == palette
                            let swatchColor = palette.color(isFemale: store.isFemale)
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                    store.state.settings.accentTheme = palette
                                    store.saveImmediate()
                                }
                                HapticsAndAudio.shared.gentleTick()
                            } label: {
                                VStack(spacing: 7) {
                                    ZStack {
                                        Circle()
                                            .stroke(selected ? swatchColor : Color.clear, lineWidth: 2.5)
                                            .frame(width: 44, height: 44)
                                        Circle()
                                            .fill(swatchColor)
                                            .frame(width: 34, height: 34)
                                            .shadow(color: swatchColor.opacity(selected ? 0.45 : 0.15), radius: selected ? 8 : 3, x: 0, y: 3)
                                        if selected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .heavy))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    Text(palette.displayName)
                                        .font(.system(size: 12, weight: selected ? .bold : .medium))
                                        .foregroundColor(selected ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(selected ? swatchColor.opacity(0.10) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Light / Dark / Auto Mode
                    Picker("المظهر", selection: Binding(
                        get: { store.state.settings.themeMode },
                        set: { store.state.settings.themeMode = $0; store.saveImmediate() }
                    )) {
                        ForEach(AppColorSchemeMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .background(cardBackground)

                // City Picker for Offline Astronomical Prayer Times
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        iconBadge("location.fill", color: store.accentColor)
                        Text("مدينة مواقيت الصلاة")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Picker("المدينة", selection: Binding(
                            get: { store.state.settings.userCity },
                            set: {
                                store.state.settings.userCity = $0
                                store.saveImmediate()
                                NotificationService.rescheduleAll(state: store.state)
                            }
                        )) {
                            ForEach(PrayerTimeCalculator.cities, id: \.name) { c in
                                Text(c.name).tag(c.name)
                            }
                        }
                        .tint(store.accentColor)
                    }
                    Button {
                        LocationPrayerService.shared.requestAndSync(store: store, userTriggered: true)
                        HapticsAndAudio.shared.gentleTick()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: locService.isSyncing ? "arrow.triangle.2.circlepath" : "location.fill")
                                .font(.system(size: 12.5, weight: .bold))
                            Text(locService.isSyncing ? "جاري تحديد موقعك..." : "تحديد تلقائي حسب موقعي (GPS + إنترنت)")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Capsule().fill(store.accentColor))
                    }
                    .buttonStyle(.plain)
                    if let stMsg = locService.lastStatusMessage {
                        Text(stMsg)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(store.accentColor)
                    }
                    Text("تُضبط مواقيت الصلوات تلقائياً من الإنترنت حسب موقعك مع دعم العمل بدون إنترنت.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(cardBackground)

                // Audio, Haptics & Notifications Card
                VStack(spacing: 14) {
                    settingToggleRow(
                        icon: "speaker.wave.2.fill",
                        title: "صوت قطرات الغيث",
                        isOn: Binding(
                            get: { store.state.settings.soundEnabled },
                            set: {
                                store.state.settings.soundEnabled = $0
                                HapticsAndAudio.shared.soundEnabled = $0
                                store.saveImmediate()
                            }
                        )
                    )
                    Divider().opacity(0.4)
                    settingToggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "الاهتزاز اللمسي",
                        isOn: Binding(
                            get: { store.state.settings.hapticsEnabled },
                            set: {
                                store.state.settings.hapticsEnabled = $0
                                HapticsAndAudio.shared.hapticsEnabled = $0
                                store.saveImmediate()
                            }
                        )
                    )
                    Divider().opacity(0.4)
                    settingToggleRow(
                        icon: "bell.badge.fill",
                        title: "تذكيرات الصلوات والعبادات",
                        isOn: Binding(
                            get: { store.state.settings.smartReminders },
                            set: {
                                store.state.settings.smartReminders = $0
                                store.saveImmediate()
                                NotificationService.rescheduleAll(state: store.state)
                            }
                        )
                    )
                }
                .padding(16)
                .background(cardBackground)

                // Refined Dedication Footer
                VStack(spacing: 5) {
                    Text("صُنع بحب كصدقة جارية لوالد صانع التطبيق رحمه الله")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("تطوير: خالد الفقيه • @9.uk00 • الإصدار 5.2")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(store.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(store.accentColor.opacity(0.06))
                )
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            OnboardingSheetView(isEditMode: true) {
                showEditProfile = false
                NotificationService.rescheduleAll(state: store.state)
            }
            .environmentObject(store)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
    }

    private func iconBadge(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.14))
                .frame(width: 32, height: 32)
            Image(systemName: name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
    }

    private func settingToggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon, color: store.accentColor)
            Toggle(title, isOn: isOn)
                .font(.system(size: 14.5, weight: .semibold))
                .tint(store.accentColor)
        }
    }

    private func statBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(store.accentColor.opacity(0.85))
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
