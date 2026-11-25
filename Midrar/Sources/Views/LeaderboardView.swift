import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var store: MidrarStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("المتنافسون في الذكر")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(store.accentColor)
                        Text("﴿وَفِي ذَٰلِكَ فَلْيَتَنَافَسِ الْمُتَنَافِسُونَ﴾")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        store.refreshLeaderboardAndConfig()
                        HapticsAndAudio.shared.gentleTick()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("تحديث")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(store.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.cardSurface).overlay(Capsule().stroke(Color.cardBorder)))
                    }
                }
                .padding(.top, 8)

                Text(store.leaderboardOnline ? "متصل مباشر — أفضل ٣٠ متنافساً" : "وضع بدون إنترنت — يتم التحديث محلياً والمزامنة عند الاتصال")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.cardSurface))

                if store.leaderboard.count >= 3 {
                    HStack(alignment: .bottom, spacing: 8) {
                        podiumCard(rank: "٢", entry: store.leaderboard[1], elevated: false)
                        podiumCard(rank: "١", entry: store.leaderboard[0], elevated: true)
                        podiumCard(rank: "٣", entry: store.leaderboard[2], elevated: false)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(Array(store.leaderboard.enumerated()), id: \.element.user_id) { idx, entry in
                        let isSelf = (entry.user_id == store.state.userId)
                        HStack(spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isSelf ? store.accentColor : .secondary)
                                .frame(width: 26)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.display_name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(isSelf ? store.accentColor : .primary)
                                Text("سلسلة \(entry.current_streak) يوم")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(entry.total_istighfar)")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(store.accentColor)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.cardSurface)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelf ? store.accentColor : Color.cardBorder, lineWidth: isSelf ? 1.6 : 1))
                        )
                    }
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            store.refreshLeaderboardAndConfig()
        }
    }

    private func podiumCard(rank: String, entry: LeaderboardEntry, elevated: Bool) -> some View {
        VStack(spacing: 4) {
            Text(rank)
                .font(.system(size: elevated ? 22 : 17, weight: .heavy))
                .foregroundColor(elevated ? Color(hex: "C68A2E") : store.accentColor)
            Text(entry.display_name)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
            Text("\(entry.total_istighfar)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(store.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, elevated ? 16 : 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardSurface)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(elevated ? Color(hex: "C68A2E") : Color.cardBorder, lineWidth: elevated ? 1.5 : 1))
        )
    }
}
