import SwiftUI

struct MainTabContainerView: View {
    @EnvironmentObject var store: MidrarStore
    @State private var selectedTab: Int = 0
    @State private var showOnboarding: Bool = false
    @State private var bannerDismissTask: Task<Void, Never>?
    @Namespace private var tabNamespace

    private let tabs: [(title: String, icon: String)] = [
        ("الواحة", "leaf"),
        ("العبادات", "checkmark.square"),
        ("التصنيف", "trophy"),
        ("الأثر", "heart"),
        ("ملفي", "person.crop.circle")
    ]

    var body: some View {
        ZStack(alignment: .top) {
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
            .id(selectedTab)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
            .animation(.spring(response: 0.30, dampingFraction: 0.86), value: selectedTab)

            // Subtle Top Safe-Area Scrim on Scrollable Tabs so Dynamic Island & Clock never collide with scrolled text
            if selectedTab != 0 {
                LinearGradient(
                    colors: [
                        Color.appBackground,
                        Color.appBackground.opacity(0.92),
                        Color.appBackground.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 68)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
            }

            // Sleek Native-Style Top Notification Banner (Replaces intrusive center-screen Alert!)
            if let ann = store.activeAnnouncement {
                topAnnouncementBanner(ann)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(99)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: store.activeAnnouncement?.announcement_title)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomDock
        }
        .onAppear {
            NotificationService.configureDelegate()
            if !store.state.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: store.activeAnnouncement?.announcement_title) { newVal in
            bannerDismissTask?.cancel()
            guard newVal != nil else { return }
            bannerDismissTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    store.activeAnnouncement = nil
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingSheetView(isEditMode: false) {
                showOnboarding = false
                NotificationService.requestAndSchedule(state: store.state)
            }
            .environmentObject(store)
        }
        .alert("مبارك إتمام الدورة 🏅", isPresented: $store.showCycleCelebration) {
            Button("الحمد لله") { store.showCycleCelebration = false }
        } message: {
            Text("أتممت ١٥,٠٠٠ ذكر ورويت واحتك بالكامل! حصلت على وسام الإنجاز الذهبي 🏅 بجانب اسمك.")
        }
    }

    private func topAnnouncementBanner(_ ann: RemoteAppConfig) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(store.accentColor.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(store.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ann.announcement_title ?? "تنبيه من مدرار")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if let body = ann.announcement_body, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 4)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    store.activeAnnouncement = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.primary.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.9)
                )
                .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 8)
        )
        .gesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height < -10 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            store.activeAnnouncement = nil
                        }
                    }
                }
        )
    }

    private var bottomDock: some View {
        HStack(spacing: 4) {
            ForEach(0..<tabs.count, id: \.self) { idx in
                let isSelected = (selectedTab == idx)
                Button {
                    guard selectedTab != idx else { return }
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                        selectedTab = idx
                    }
                    HapticsAndAudio.shared.gentleTick()
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(store.accentColor.opacity(0.16))
                                    .frame(width: 54, height: 30)
                                    .matchedGeometryEffect(id: "activeTabPill", in: tabNamespace)
                            }
                            Image(systemName: isSelected ? "\(tabs[idx].icon).fill" : tabs[idx].icon)
                                .font(.system(size: idx == 2 ? 19 : 18, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? store.accentColor : .secondary)
                                .scaleEffect(isSelected ? 1.06 : 1.0)
                        }
                        .frame(height: 30)

                        Text(tabs[idx].title)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? store.accentColor : .secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 9)
                    .padding(.bottom, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .background(
            TopRoundedShape(radius: 26)
                .fill(.ultraThinMaterial)
                .overlay(
                    TopRoundedShape(radius: 26)
                        .fill(Color.appBackground.opacity(0.72))
                )
                .overlay(
                    TopRoundedShape(radius: 26)
                        .stroke(Color.primary.opacity(0.07), lineWidth: 0.75)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
