import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject var store: MidrarStore
    @State private var showEditProfile = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("ملفي وإعداداتي")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(store.accentColor)
                    .padding(.top, 8)

                // Profile Card
                HStack(spacing: 12) {
                    Circle()
                        .fill(store.accentColor.opacity(0.15))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundColor(store.accentColor)
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        let medal = store.state.completedCyclesCount > 0 ? " 🏅\(store.state.completedCyclesCount)" : ""
                        Text((store.state.userName.isEmpty ? "أهلاً بك في مدرار" : store.state.userName) + medal)
                            .font(.system(size: 15, weight: .bold))
                        Text(store.state.userAge > 0 ? "العمر \(store.state.userAge) • \(store.isFemale ? "أنثى" : "ذكر")" : "اضغط لتخصيص ملفك")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("تعديل") { showEditProfile = true }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(store.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.appBackground).overlay(Capsule().stroke(Color.cardBorder)))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder)))

                // Stats Summary
                HStack {
                    statBox(value: "\(store.state.totalIstighfar)", label: "إجمالي الذكر")
                    Divider().frame(height: 30)
                    statBox(value: "\(store.state.currentStreak)", label: "سلسلة الأيام")
                    Divider().frame(height: 30)
                    statBox(value: "\(store.currentStage)", label: "مستوى الواحة")
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder)))

                // Accent Theme Picker (Olive / Blue / Rose / Sand)
                VStack(alignment: .leading, spacing: 8) {
                    Text("لون هوية التطبيق")
                        .font(.system(size: 13.5, weight: .bold))
                    HStack(spacing: 8) {
                        ForEach([AccentPalette.olive, .blue, .rose, .sand], id: \.self) { palette in
                            let selected = store.state.settings.accentTheme == palette
                            Button {
                                store.state.settings.accentTheme = palette
                                store.saveImmediate()
                                HapticsAndAudio.shared.gentleTick()
                            } label: {
                                Text(palette.displayName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Capsule().fill(palette.color(isFemale: store.isFemale)))
                                    .opacity(selected ? 1.0 : 0.62)
                            }
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
                    .padding(.top, 4)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder)))

                // City Picker for Offline Astronomical Prayer Times
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("مدينة مواقيت الصلاة")
                            .font(.system(size: 13.5, weight: .bold))
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
                    Text("تُحسب مواقيت الصلوات الخمس وتُضبط الإشعارات عليها بدون إنترنت.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder)))

                // Toggles: Sound, Haptics, Notifications
                VStack(spacing: 12) {
                    Toggle("صوت قطرات الغيث", isOn: Binding(
                        get: { store.state.settings.soundEnabled },
                        set: {
                            store.state.settings.soundEnabled = $0
                            HapticsAndAudio.shared.soundEnabled = $0
                            store.saveImmediate()
                        }
                    ))
                    Divider()
                    Toggle("الاهتزاز اللمسي", isOn: Binding(
                        get: { store.state.settings.hapticsEnabled },
                        set: {
                            store.state.settings.hapticsEnabled = $0
                            HapticsAndAudio.shared.hapticsEnabled = $0
                            store.saveImmediate()
                        }
                    ))
                    Divider()
                    Toggle("تذكيرات الصلوات والعبادات", isOn: Binding(
                        get: { store.state.settings.smartReminders },
                        set: {
                            store.state.settings.smartReminders = $0
                            store.saveImmediate()
                            NotificationService.rescheduleAll(state: store.state)
                        }
                    ))
                }
                .tint(store.accentColor)
                .font(.system(size: 13.5, weight: .semibold))
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder)))

                // Creator Footer
                VStack(alignment: .center, spacing: 4) {
                    Text("صُنع بحب كصدقة جارية لوالد صانع التطبيق رحمه الله")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                    Text("تطوير: خالد الفقيه • @9.uk00")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(store.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 16)
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            OnboardingSheetView(isEditMode: true) {
                showEditProfile = false
                NotificationService.rescheduleAll(state: store.state)
            }
            .environmentObject(store)
        }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(store.accentColor)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
