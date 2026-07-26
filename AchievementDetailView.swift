import SwiftUI

struct AchievementDetailView: View {
    let achievement: AchievementDefinition
    let progress: AchievementProgress
    let userRank: UserRankData
    @Environment(\.dismiss) var dismiss
    
    var ct: AchievementTier? { achievement.currentTier(progress: progress.currentValue) }
    var nt: AchievementTier? { achievement.nextTier(progress: progress.currentValue) }
    var tc: Color {
        guard let t = ct else { return .gray }
        let r = Double(t.tier) / Double(max(achievement.tiers.count, 1))
        return Color(red: 0.3 + 0.7 * r, green: 0.7 - 0.4 * r, blue: 0.9 - 0.3 * r)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 32) {
                        HStack {
                            Spacer()
                            Button { dismiss() } label: {
                                Text("✕").font(.system(size: 24, weight: .bold)).foregroundColor(.gray).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                            }
                        }.padding(.horizontal, 20).padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            ZStack {
                                Circle().fill(tc.opacity(0.15)).frame(width: 140, height: 140).blur(radius: 30)
                                AchievementBadgeView2(tier: ct?.tier ?? 1, maxTier: achievement.tiers.count, size: 110)
                            }
                            Text(ct?.name ?? achievement.title).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            Text(achievement.title).font(.system(size: 14)).foregroundColor(tc).tracking(1).padding(.horizontal, 14).padding(.vertical, 4).background(Capsule().fill(tc.opacity(0.12)))
                            if let t = ct { Text(t.vibe).font(.system(size: 13)).foregroundColor(.gray).italic() }
                        }
                        .padding(.vertical, 24).frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 32).fill(.ultraThinMaterial.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 32).stroke(tc.opacity(0.2), lineWidth: 0.5)))
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ĐIỀU KIỆN").font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.4)).tracking(2)
                            ForEach(achievement.tiers) { t in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(tc2(t).opacity(progress.unlockedTiers.contains(t.tier) ? 0.15 : 0.03)).frame(width: 36, height: 40)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tc2(t).opacity(progress.unlockedTiers.contains(t.tier) ? 0.4 : 0.08), lineWidth: 1))
                                        Text(progress.unlockedTiers.contains(t.tier) ? "✓" : "○")
                                            .font(.system(size: 16, weight: progress.unlockedTiers.contains(t.tier) ? .bold : .light))
                                            .foregroundColor(progress.unlockedTiers.contains(t.tier) ? tc2(t) : .gray.opacity(0.4))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.name).font(.system(size: 13, weight: .medium)).foregroundColor(progress.unlockedTiers.contains(t.tier) ? .white : .gray.opacity(0.5))
                                        Text(t.description).font(.system(size: 11)).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    if progress.unlockedTiers.contains(t.tier) {
                                        Text("✓").font(.system(size: 14, weight: .bold)).foregroundColor(tc2(t))
                                    }
                                }.padding(10).background(RoundedRectangle(cornerRadius: 14).fill(progress.unlockedTiers.contains(t.tier) ? .white.opacity(0.03) : .clear))
                            }
                        }.padding(.horizontal, 20)
                        
                        if let n = nt {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Tiến độ →").font(.system(size: 13)).foregroundColor(.gray)
                                    Text(n.name).font(.system(size: 13, weight: .bold)).foregroundColor(tc)
                                }
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 5).fill(Color(white: 0.18)).frame(height: 10)
                                        RoundedRectangle(cornerRadius: 5).fill(LinearGradient(colors: [tc, tc.opacity(0.4)], startPoint: .leading, endPoint: .trailing)).frame(width: g.size.width * n.progress(current: progress.currentValue), height: 10)
                                    }
                                }.frame(height: 10)
                                Text("\(progress.currentValue) / \(n.requirement)").font(.system(size: 15, design: .monospaced)).foregroundColor(.white)
                                Text(n.vibe).font(.system(size: 11)).foregroundColor(.gray).italic()
                            }.padding(20).background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 24).stroke(tc.opacity(0.15), lineWidth: 0.5))).padding(.horizontal, 20)
                        }
                        Spacer().frame(height: 60)
                    }
                }
            }.navigationBarHidden(true)
        }
    }
    func tc2(_ t: AchievementTier) -> Color {
        let r = Double(t.tier) / Double(max(achievement.tiers.count, 1))
        return Color(red: 0.3 + 0.7 * r, green: 0.7 - 0.4 * r, blue: 0.9 - 0.3 * r)
    }
}