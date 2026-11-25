import SwiftUI

struct ImpactView: View {
    @EnvironmentObject var store: MidrarStore
    @State private var showAddDua = false
    @State private var newDuaText = ""

    private var appShareText: String {
        let dl = SupabaseService.shared.getCachedDownloadURL()
        return "أنصحك بتطبيق «مدرار» للاستغفار والأذكار ومتابعة العبادات اليومية — صدقة جارية لوالد صانع التطبيق رحمه الله.\n\nرابط التحميل المباشر:\n\(dl)"
    }

    private var storyShareText: String {
        "بفضل الله وصلت إلى \(store.state.totalIstighfar) ذكر في تطبيق «مدرار» وسلسلة \(store.state.currentStreak) يوم."
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("الأثر والدعاء")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(store.accentColor)
                    .padding(.top, 8)

                Text("﴿وَمَا تُقَدِّمُوا لِأَنفُسِكُم مِّنْ خَيْرٍ تَجِدُوهُ عِندَ اللَّهِ هُوَ خَيْرًا وَأَعْظَمَ أَجْرًا﴾")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                // Private Duas Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("أدعيتي الخاصة")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(store.accentColor)
                    Text("سجّل دعواتك الخاصة لتدعو بها مع كل جلسة ذكر.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)

                    ForEach(store.state.duas) { dua in
                        HStack {
                            Text(dua.text)
                                .font(.system(size: 13.5, weight: .medium))
                            Spacer()
                            Button {
                                for i in store.state.duas.indices {
                                    store.state.duas[i].isPinned = (store.state.duas[i].id == dua.id) ? !store.state.duas[i].isPinned : false
                                }
                                store.saveImmediate()
                            } label: {
                                Image(systemName: dua.isPinned ? "pin.fill" : "pin")
                                    .foregroundColor(dua.isPinned ? store.accentColor : .secondary)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.appBackground))
                    }

                    Button {
                        showAddDua = true
                    } label: {
                        Text("+ إضافة دعوة جديدة")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(store.accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Capsule().fill(Color.appBackground).overlay(Capsule().stroke(Color.cardBorder)))
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.cardBorder)))

                // Share Progress & App Link Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("مشاركة الأثر وتطبيق مدرار")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "C68A2E"))
                    Text("شارك ثمرة ذكرك أو أرسل رابط تحميل تطبيق مدرار لمن تحب، فالدال على الخير كفاعله.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    ShareLink(item: storyShareText) {
                        Text("مشاركة إنجازك في الستوري")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Capsule().fill(store.accentColor))
                    }

                    ShareLink(item: appShareText) {
                        Text("مشاركة رابط تحميل التطبيق")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(store.accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Capsule().fill(Color.appBackground).overlay(Capsule().stroke(Color.cardBorder)))
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cardSurface).overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.cardBorder)))

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 16)
        }
        .alert("إضافة دعوة جديدة", isPresented: $showAddDua) {
            TextField("اكتب دعوتك هنا...", text: $newDuaText)
            Button("حفظ") {
                let t = newDuaText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty {
                    store.state.duas.append(DuaItem(text: t, isPinned: store.state.duas.isEmpty))
                    store.saveImmediate()
                    newDuaText = ""
                }
            }
            Button("إلغاء", role: .cancel) {}
        }
    }
}
