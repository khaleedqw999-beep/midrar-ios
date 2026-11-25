import SwiftUI

struct OnboardingSheetView: View {
    @EnvironmentObject var store: MidrarStore
    let isEditMode: Bool
    let onFinish: () -> Void

    @State private var step: Int = 0
    @State private var nameInput: String = ""
    @State private var ageInput: String = ""
    @State private var genderInput: String = "male"
    @State private var validationMsg: String?

    private let totalSteps = 5

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.38).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("مدرار")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(store.accentColor)
                    Spacer()
                    if isEditMode || step < totalSteps - 1 {
                        Button(isEditMode ? "إغلاق" : "تخطي") {
                            if isEditMode {
                                onFinish()
                            } else {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                                    step = totalSteps - 1
                                }
                            }
                        }
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)

                Spacer()

                // 60/120fps Animated Slides
                Group {
                    switch step {
                    case 0: welcomeSlide
                    case 1: featureOasisSlide
                    case 2: featureTrackerSlide
                    case 3: featureLeaderboardSlide
                    default: profileSlide
                    }
                }
                .padding(.horizontal, 24)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.96)),
                    removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.96))
                ))
                .id(step)

                Spacer()

                // Progress Dots + Next / Start Button
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        ForEach(0..<totalSteps, id: \.self) { i in
                            Capsule()
                                .fill(i == step ? (genderInput == "female" ? Color(hex: "C8467C") : store.accentColor) : Color.cardBorder)
                                .frame(width: i == step ? 24 : 8, height: 7)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: step)
                        }
                    }

                    Button {
                        if step < totalSteps - 1 {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                                step += 1
                            }
                            HapticsAndAudio.shared.gentleTick()
                        } else {
                            saveProfile()
                        }
                    } label: {
                        Text(step == totalSteps - 1 ? (genderInput == "female" ? "ابدئي رحلة الغيث" : "ابدأ رحلة الغيث") : "التالي")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Capsule().fill(genderInput == "female" ? Color(hex: "C8467C") : store.accentColor))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    Color.appBackground
                    Circle()
                        .fill(store.accentColor.opacity(0.16))
                        .frame(width: 260, height: 260)
                        .blur(radius: 55)
                        .offset(x: 110, y: -280)
                    Circle()
                        .fill(Color(hex: "9A6B2F").opacity(0.12))
                        .frame(width: 220, height: 220)
                        .blur(radius: 50)
                        .offset(x: -110, y: 240)
                }
                .clipShape(TopRoundedShape(radius: 28))
            )
            .padding(.top, 26)
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            nameInput = store.state.userName
            ageInput = store.state.userAge > 0 ? String(store.state.userAge) : ""
            genderInput = store.state.userGender
            if isEditMode {
                step = totalSteps - 1
            }
        }
    }

    private var welcomeSlide: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill")
                .font(.system(size: 42))
                .foregroundColor(store.accentColor)
                .frame(width: 82, height: 82)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.cardSurface))

            Text("بسم الله الرحمن الرحيم")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(store.accentColor)

            Text("أهلاً بك في مدرار")
                .font(.system(size: 26, weight: .bold))

            VStack(spacing: 12) {
                Text("﴿ فَقُلْتُ اسْتَغْفِرُوا رَبَّكُمْ إِنَّهُ كَانَ غَفَّارًا ۝ يُرْسِلِ السَّمَاءَ عَلَيْكُم مِّدْرَارًا ﴾")
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                Text("﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(store.accentColor)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder)))

            Text("رفيقك اليومي الهادئ للاستغفار والأذكار ومتابعة العبادات بتصميم مريح للعين.")
                .font(.system(size: 13.5))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureOasisSlide: some View {
        featureTemplate(
            icon: "leaf",
            title: "واحة حية تنمو بذكرك",
            subtitle: "رحلة ٣٠ يوماً تتبدل فيها أرضك القاحلة إلى واحة خضراء مع كل استغفارة، مع سماء حية تتغير مع الفجر والظهر والغروب والليل.",
            bullets: [
                "التسبيح باللمس أو الصوت بدون إنترنت",
                "أذكار الصباح والمساء المتسلسلة بسُقيا الواحة",
                "لمسة يوم الجمعة المبارك بالصلاة على النبي ﷺ"
            ]
        )
    }

    private var featureTrackerSlide: some View {
        featureTemplate(
            icon: "calendar.badge.checkmark",
            title: "متابعة العبادات والعادات",
            subtitle: "تابع صلواتك الخمس بمواقيت مدينتك الفلكية بدون إنترنت، وأذكارك اليومية، وورد القرآن، والسنن الرواتب، والضحى، والوتر، والصيام في مكان واحد مرتب.",
            bullets: [
                "حساب نسبة إنجازك اليومية تلقائياً (0% إلى 100%)",
                "إشعارات لطيفة بعد الصلوات وفي أوقات الضحى والوتر",
                "ألوان مريحة للعين قابلة للتخصيص من الإعدادات"
            ]
        )
    }

    private var featureLeaderboardSlide: some View {
        featureTemplate(
            icon: "trophy",
            title: "وفي ذلك فليتنافس المتنافسون",
            subtitle: "نافس في قائمة أفضل ٣٠ مستغفراً وذاكراً حتى بدون إنترنت، واحصل على وسام إتمام الدورة الذهبي 🏅 بجانب اسمك.",
            bullets: [
                "تحديث تلقائي مع السيرفر ومزامنة دون اتصال",
                "أوسمة دائمة عند إتمام ١٥,٠٠٠ ذكر"
            ]
        )
    }

    private func featureTemplate(icon: String, title: String, subtitle: String, bullets: [String]) -> some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundColor(store.accentColor)
                .frame(width: 80, height: 80)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.cardBorder)))

            Text(title)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 13.5))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(bullets, id: \.self) { item in
                    HStack(spacing: 8) {
                        Circle().fill(store.accentColor).frame(width: 6, height: 6)
                        Text(item).font(.system(size: 13))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cardBorder)))
        }
    }

    private var profileSlide: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text("خصّص ملفك في مدرار")
                    .font(.system(size: 21, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("الاسم مع اللقب")
                    .font(.system(size: 12.5, weight: .bold))
                TextField("مثال: خالد الفقيه", text: $nameInput)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder)))

                Text("العمر")
                    .font(.system(size: 12.5, weight: .bold))
                TextField("مثال: 24", text: $ageInput)
                    .keyboardType(.numberPad)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder)))

                Text("اختر الهوية (يمكنك تغيير الألوان لاحقاً من الإعدادات)")
                    .font(.system(size: 12, weight: .bold))

                HStack(spacing: 10) {
                    Button {
                        genderInput = "male"
                    } label: {
                        Text("ذكر (أخضر زيتوني)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(genderInput == "male" ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Capsule().fill(genderInput == "male" ? Color(hex: "4A6741") : Color.cardSurface))
                    }

                    Button {
                        genderInput = "female"
                    } label: {
                        Text("أنثى (وردي هادئ)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(genderInput == "female" ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Capsule().fill(genderInput == "female" ? Color(hex: "C8467C") : Color.cardSurface))
                    }
                }

                if let msg = validationMsg {
                    Text(msg)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
    }

    private func saveProfile() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMsg = "يرجى كتابة الاسم مع اللقب أولاً"
            return
        }
        let age = Int(ageInput.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        guard age > 0 && age <= 120 else {
            validationMsg = "يرجى إدخال عمر صحيح"
            return
        }
        store.state.userName = trimmed
        store.state.userAge = age
        store.state.userGender = genderInput
        store.state.hasCompletedOnboarding = true
        store.saveImmediate()
        store.refreshLeaderboardAndConfig()
        onFinish()
    }
}
