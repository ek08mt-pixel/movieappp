import SwiftUI

struct AchievementView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = AchievementManager.shared
    @State private var selectedCategory: AchievementCategory = .all
    @State private var selectedAchievement: AchievementDefinition?
    @State private var showDetail = false
    
    private let achievements = AchievementData.all
    
    var filteredAchievements: [AchievementDefinition] {
        if selectedCategory == .all { return achievements }
        return achievements.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        headerView.padding(.top, 60)
                        rankCard.padding(.horizontal, 20)
                        timelineView.padding(.horizontal, 20)
                        categoryFilter.padding(.horizontal, 20)
                        achievementGrid.padding(.horizontal, 20)
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDetail) {
                if let a = selectedAchievement, let p = manager.progress(for: a.id) {
                    AchievementDetailView(achievement: a, progress: p, userRank: manager.userRankData)
                }
            }
        }
        .onAppear { manager.refresh(from: appState) }
    }
    
    var headerView: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Text("←").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                    .padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
            }
            Text("Danh Hiệu").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
            Spacer()
            Text("\(manager.userRankData.unlockedAchievements)/\(manager.userRankData.totalAchievements)")
                .font(.system(size: 12, design: .monospaced)).foregroundColor(.gray)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(.ultraThinMaterial.opacity(0.3)))
        }.padding(.horizontal, 20)
    }
    
    var rankCard: some View {
        let cr = manager.userRankData.currentRank
        let nr = manager.userRankData.nextRank
        let xpIn = manager.userRankData.totalXP - cr.xpRequired
        let xpRange = max((nr?.xpRequired ?? cr.xpRequired * 2) - cr.xpRequired, 1)
        
        return ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 32).stroke(
                    LinearGradient(colors: [cr.color.opacity(0.25), .white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            
            VStack(spacing: 14) {
                RankBadgeView(rank: cr, size: 110)
                
                Text(cr.shortName).font(.system(size: 13, weight: .bold)).foregroundColor(cr.color).tracking(2)
                    .padding(.horizontal, 12).padding(.vertical, 4).background(Capsule().fill(cr.color.opacity(0.15)))
                Text(cr.rawValue).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(cr.tagline).font(.system(size: 12)).foregroundColor(.gray).italic()
                Text("Level \(manager.userRankData.level)").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text("Top \(manager.userRankData.percentile)%").font(.system(size: 11)).foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.2)).frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [cr.color, cr.color.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(6, geo.size.width * CGFloat(min(max(Double(xpIn)/Double(xpRange), 0), 1))), height: 6)
                        }
                    }.frame(height: 6)
                    HStack {
                        Text("\(manager.userRankData.totalXP) XP").font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                        Spacer()
                        if let n = nr {
                            Text("Còn \(n.xpRequired - manager.userRankData.totalXP) XP → \(n.shortName)").font(.system(size: 11)).foregroundColor(cr.color.opacity(0.7))
                        }
                    }
                }
            }.padding(24)
        }.frame(minHeight: 320)
    }
    
    var timelineView: some View {
        let cr = manager.userRankData.currentRank
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(Rank.allCases.enumerated()), id: \.element) { i, rank in
                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            ZStack {
                                GameShield()
                                    .fill(rank == cr ? rank.color.opacity(0.2) : .white.opacity(0.03))
                                    .frame(width: 40, height: 44)
                                    .overlay(GameShield().stroke(rank == cr ? rank.color.opacity(0.5) : .white.opacity(0.08), lineWidth: rank == cr ? 2 : 0.5))
                                Text(rank.shortName.prefix(1))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(rank == cr ? rank.color : .gray)
                            }
                            Text(rank.shortName).font(.system(size: 7)).foregroundColor(rank == cr ? rank.color : .gray).lineLimit(1)
                            Text("Lv\(rank.level)").font(.system(size: 7)).foregroundColor(.gray)
                        }.frame(width: 52)
                        if i < Rank.allCases.count - 1 {
                            Rectangle().fill(rank.xpRequired < manager.userRankData.totalXP ? cr.color.opacity(0.5) : Color(white: 0.18)).frame(width: 12, height: 2)
                        }
                    }
                }
            }.padding(.horizontal, 12)
        }
    }
    
    var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AchievementCategory.allCases, id: \.self) { c in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedCategory = c }
                    } label: {
                        Text(c.rawValue).font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedCategory == c ? .white : .gray)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(selectedCategory == c ? .white.opacity(0.15) : .white.opacity(0.05)))
                            .overlay(Capsule().stroke(selectedCategory == c ? .white.opacity(0.2) : .clear, lineWidth: 0.5))
                    }
                }
            }
        }
    }
    
    var achievementGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 14) {
            ForEach(filteredAchievements) { a in
                if let p = manager.progress(for: a.id) {
                    AchievementCard2(achievement: a, progress: p)
                        .onTapGesture { selectedAchievement = a; showDetail = true }
                }
            }
        }
    }
}

struct AchievementCard2: View {
    let achievement: AchievementDefinition
    let progress: AchievementProgress
    var ct: AchievementTier? { achievement.currentTier(progress: progress.currentValue) }
    var nt: AchievementTier? { achievement.nextTier(progress: progress.currentValue) }
    var done: Bool { nt == nil }
    var tc: Color {
        guard let t = ct else { return .gray }
        let r = Double(t.tier) / Double(max(achievement.tiers.count, 1))
        return Color(red: 0.3 + 0.7 * r, green: 0.7 - 0.4 * r, blue: 0.9 - 0.3 * r)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            AchievementBadgeView2(tier: ct?.tier ?? 1, maxTier: achievement.tiers.count, size: 56)
            Text(ct?.name ?? achievement.title).font(.system(size: 13, weight: .bold)).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.center).frame(height: 36)
            if let n = nt {
                Text("\(progress.currentValue)/\(n.requirement)").font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(white: 0.2)).frame(height: 3)
                        RoundedRectangle(cornerRadius: 2).fill(LinearGradient(colors: [tc, tc.opacity(0.4)], startPoint: .leading, endPoint: .trailing)).frame(width: g.size.width * n.progress(current: progress.currentValue), height: 3)
                    }
                }.frame(height: 3).padding(.horizontal, 8)
            } else if done {
                Text("✦ MAX").font(.system(size: 10, weight: .bold)).foregroundColor(tc).padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(tc.opacity(0.12)))
            }
        }
        .padding(14).frame(height: 175).frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5))
        .shadow(color: done ? tc.opacity(0.12) : .black.opacity(0.3), radius: 10, y: 5)
    }
}