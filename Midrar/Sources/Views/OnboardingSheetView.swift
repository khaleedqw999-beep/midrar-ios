import SwiftUI
import UIKit

struct OnboardingSheetView: View {
    @EnvironmentObject var store: MidrarStore
    let isEditMode: Bool
    let onFinish: () -> Void

    private enum InputField: Hashable {
        case name
        case age
    }

    @FocusState private var focusedField: InputField?
    @State private var step: Int = 0
    @State private var nameInput: String = ""
    @State private var ageInput: String = ""
    @State private var genderInput: String = "male"
    @State private var validationMsg: String?

    private let totalSteps = 5

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismissKeyboard() }

            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 13))
                            .foregroundColor(store.accentColor)
                        Text("مِدْرَار")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(store.accentColor)
                    }
                    Spacer()
                    if isEditMode || step < totalSteps - 1 {
                        Button(isEditMode ? "إغلاق" : "تخطي") {
                            dismissKeyboard()
                            if isEditMode {
                                onFinish()
                            } else {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                                    step = totalSteps - 1
                                }
                            }
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.cardSurface))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)

                Spacer(minLength: 10)

                // 120Hz Animated Slides
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

                Spacer(minLength: 10)

                // Dots Indicator
                HStack(spacing: 7) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? store.accentColor : store.accentColor.opacity(0.22))
                            .frame(width: i == step ? 26 : 8, height: 7)
                            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: step)
                    }
                }
                .padding(.bottom, 16)

                // Primary CTA Button
                Button {
                    dismissKeyboard()
                    if step < totalSteps - 1 {
                        withAnimation(.spring(response: 0.44, dampingFraction: 0.84)) {
                            step += 1
                        }
                        HapticsAndAudio.shared.gentleTick()
                    } else {
                        saveProfile()
                    }
                } label: {
                    Text(step == totalSteps - 1 ? (isEditMode ? "حفظ التعديلات" : "ابدأ رحلة الغيث") : "التالي")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            Capsule()
                                .fill(store.accentColor)
                                .shadow(color: store.accentColor.opacity(0.32), radius: 12, x: 0, y: 6)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    Color.appBackground
                    Circle()
                        .fill(store.accentColor.opacity(0.11))
                        .frame(width: 280, height: 280)
                        .blur(radius: 50)
                        .offset(x: 130, y: -270)
                    Circle()
                        .fill(Color(hex: "C68A2E").opacity(0.08))
                        .frame(width: 220, height: 220)
                        .blur(radius: 50)
                        .offset(x: -130, y: 240)
                }
            )
            .clipShape(TopRoundedShape(radius: 30))
            .padding(.top, 18)
            .ignoresSafeArea(edges: .bottom)
            .contentShape(Rectangle())
            .onTapGesture { dismissKeyboard() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("تم") {
                    dismissKeyboard()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(store.accentColor)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            nameInput = store.state.userName
            ageInput = store.state.userAge > 0 ? "\(store.state.userAge)" : ""
            genderInput = store.state.userGender
            if isEditMode { step = totalSteps - 1 }
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var welcomeSlide: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(store.accentColor.opacity(0.14))
                    .frame(width: 88, height: 88)
                Image(systemName: "drop.fill")
                    .font(.system(size: 36))
                    .foregroundColor(store.accentColor)
            }
            Text("أهلاً بك في مِدْرَار")
                .font(.system(size: 26, weight: .heavy))
            Text("﴿ فَقُلْتُ اسْتَغْفِرُوا رَبَّكُمْ إِنَّهُ كَانَ غَفَّارًا ۝ يُرْسِلِ السَّمَاءَ عَلَيْكُم مِّدْرَارًا ﴾")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(store.accentColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Text("واحتك اليومية للاستغفار، الذكر بالصوت أو اللمس، ومتابعة عباداتك الخمس بكل هدوء وسكينة.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var featureOasisSlide: some View {
        featureTemplate(
            icon: "leaf.fill",
            title: "واحة حيّة تنمو بذكرك",
            subtitle: "كل تسبيحة واستغفار تسقي واحتك وتُزهر أرضك على مدار الشهر.",
            bullets: [
                "رحلة ٣٠ يوماً (١٥,٠٠٠ ذكر) نحو واحة مثمرة كاملة",
                "الذكر بالصوت بدون إنترنت أو باللمس والاهتزاز الهادئ",
                "مؤثرات مطر وغيوم حية تتفاعل مع كل ضغطة"
            ]
        )
    }

    private var featureTrackerSlide: some View {
        featureTemplate(
            icon: "checkmark.seal.fill",
            title: "متابعة العبادات اليومية",
            subtitle: "الصلوات الخمس، أذكار الصباح والمساء، السنن الرواتب، والقرآن في مكان واحد.",
            bullets: [
                "مواقيت صلاة فلكية دقيقة لمدينتك بدون إنترنت",
                "أذكار متسلسلة مع عداد تفاعلي ومكتبة أذكار كاملة",
                "إشعارات علوية لطيفة ومؤدبة في أوقات الصلوات"
            ]
        )
    }

    private var featureLeaderboardSlide: some View {
        featureTemplate(
            icon: "trophy.fill",
            title: "تنافس في الخير بلا ضجيج",
            subtitle: "﴿ وَفِي ذَٰلِكَ فَلْيَتَنَافَسِ الْمُتَنَافِسُونَ ﴾",
            bullets: [
                "ترتيب حي لأكثر الذاكرين في مدرار",
                "وسام الإنجاز الذهبي 🏅 عند إتمام دورة ١٥,٠٠٠ ذكر",
                "تخصيص كامل لألوان الهوية والمظهر النهاري والليلي"
            ]
        )
    }

    private func featureTemplate(icon: String, title: String, subtitle: String, bullets: [String]) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(store.accentColor.opacity(0.14))
                    .frame(width: 82, height: 82)
                Image(systemName: icon)
                    .font(.system(size: 34))
                    .foregroundColor(store.accentColor)
            }
            Text(title)
                .font(.system(size: 22, weight: .heavy))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 13.5))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 11) {
                ForEach(bullets, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(store.accentColor)
                        Text(item)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.cardSurface)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.cardBorder))
            )
        }
    }

    private var profileSlide: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 6) {
                    Text("خصّص ملفك في مدرار")
                        .font(.system(size: 23, weight: .heavy))
                    Text("اضغط خارج الحقول أو على «تم» لإغلاق لوحة المفاتيح")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)

                // Name Input
                VStack(alignment: .leading, spacing: 7) {
                    Text("الاسم مع اللقب")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 15))
                            .foregroundColor(focusedField == .name ? store.accentColor : .secondary)
                        TextField("مثال: خالد الفقيه", text: $nameInput)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .age }
                    }
                    .padding(15)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(focusedField == .name ? store.accentColor : Color.cardBorder, lineWidth: focusedField == .name ? 1.6 : 1)
                            )
                    )
                }

                // Age Input
                VStack(alignment: .leading, spacing: 7) {
                    Text("العمر")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 15))
                            .foregroundColor(focusedField == .age ? store.accentColor : .secondary)
                        TextField("مثال: 24", text: $ageInput)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .age)
                        if focusedField == .age {
                            Button("تم") { dismissKeyboard() }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(store.accentColor))
                        }
                    }
                    .padding(15)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(focusedField == .age ? store.accentColor : Color.cardBorder, lineWidth: focusedField == .age ? 1.6 : 1)
                            )
                    )
                }

                // Gender / Identity Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("اختر الهوية (يمكنك تغيير الألوان لاحقاً من الإعدادات)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        genderOptionButton(
                            title: "ذكر",
                            subtitle: "أخضر زيتوني",
                            isSelected: genderInput == "male",
                            color: Color(hex: "4A6741")
                        ) {
                            dismissKeyboard()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                genderInput = "male"
                            }
                            HapticsAndAudio.shared.gentleTick()
                        }

                        genderOptionButton(
                            title: "أنثى",
                            subtitle: "وردي هادئ",
                            isSelected: genderInput == "female",
                            color: Color(hex: "C8467C")
                        ) {
                            dismissKeyboard()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                genderInput = "female"
                            }
                            HapticsAndAudio.shared.gentleTick()
                        }
                    }
                }

                if let msg = validationMsg {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(msg)
                    }
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func genderOptionButton(title: String, subtitle: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? .white : .primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? color : Color.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? color : Color.cardBorder, lineWidth: 1.2)
                    )
            )
        }
        .buttonStyle(.plain)
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
