import SwiftUI

struct MainTabContainerView: View {
    @EnvironmentObject var store: MidrarStore
    @State private var selectedTab: Int = 0
    @State private var showOnboarding: Bool = false

    private let tabs: [(title: String, icon: String)] = [
        ("الواحة", "leaf"),
        ("العبادات", "checkmark.square"),
        ("التصنيف", "trophy"),
        ("الأثر", "heart"),
        ("ملفي", "chart.bar")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            Group {
                switch selectedTab {
                case 0:
                    OasisView()
                case 1:
                    WorshipTrackerView()
                case 2:
                    LeaderboardView()
                case 3:
                    ImpactView()
                default:
                    ProfileSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .offset(y: 10)))
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: selectedTab)

            // Flush-Anchored Non-Hiding Bottom Dock with Smooth 24pt Top Corners
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { idx in
                        let isSelected = (selectedTab == idx)
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selectedTab = idx
                            }
                            HapticsAndAudio.shared.gentleTick()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: isSelected ? "\(tabs[idx].icon).fill" : tabs[idx].icon)
                                    .font(.system(size: idx == 2 ? 20 : 18, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? store.accentColor : .secondary)
                                    .scaleEffect(isSelected ? 1.08 : 1.0)
                                Text(tabs[idx].title)
                                    .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? store.accentColor : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)
                            .padding(.bottom, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .background(
                    TopRoundedShape(radius: 24)
                        .fill(Color.appBackground.opacity(0.96))
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -3)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onAppear {
            if !store.state.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingSheetView(isEditMode: false) {
                showOnboarding = false
                NotificationService.requestAndSchedule(state: store.state)
            }
            .environmentObject(store)
        }
        .alert(store.activeAnnouncement?.announcement_title ?? "تنبيه من مدرار", isPresented: Binding(
            get: { store.activeAnnouncement != nil },
            set: { if !$0 { store.activeAnnouncement = nil } }
        )) {
            Button("حسناً") { store.activeAnnouncement = nil }
        } message: {
            Text(store.activeAnnouncement?.announcement_body ?? "")
        }
        .alert("مبارك إتمام الدورة 🏅", isPresented: $store.showCycleCelebration) {
            Button("الحمد لله") { store.showCycleCelebration = false }
        } message: {
            Text("أتممت ١٥,٠٠٠ ذكر ورويت واحتك بالكامل! حصلت على وسام الإنجاز الذهبي 🏅 بجانب اسمك.")
        }
    }
}
