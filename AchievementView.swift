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
                ZStack {
                    Color.black
                    LinearGradient(
                        colors: [Color(white: 0.06), Color(white: 0.02), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                            .padding(.top, 60)
                        
                        rankCard
                            .padding(.horizontal, 20)
                        
                        timelineView
                            .padding(.horizontal, 20)
                        
                        categoryFilter
                            .padding(.horizontal, 20)
                        
                        achievementGrid
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDetail) {
                if let achievement = selectedAchievement,
                   let prog = manager.progress(for: achievement.id) {
                    AchievementDetailView(
                        achievement: achievement,
                        progress: prog,
                        userRank: manager.userRankData
                    )
                }
            }
        }
        .onAppear {
            manager.refresh(from: appState)
        }
    }
    
    var headerView: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Text("←")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
            }
            Text("Danh Hiệu")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Text("\(manager.userRankData.unlockedAchievements)/\(manager.userRankData.totalAchievements)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(.ultraThinMaterial.opacity(0.3)))
        }
        .padding(.horizontal, 20)
    }
    
    var rankCard: some View {
        let currentRank = manager.userRankData.currentRank
        let nextRank = manager.userRankData.nextRank
        let xpInRank = manager.userRankData.totalXP - currentRank.xpRequired
        let xpRange = max((nextRank?.xpRequired ?? currentRank.xpRequired * 2) - currentRank.xpRequired, 1)
        
        return ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 32)
                    .stroke(LinearGradient(colors: [currentRank.color.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            
            VStack(spacing: 14) {
                CatBadgeView(rank: currentRank, size: 100)
                
                if [Rank.master, Rank.legend, Rank.mythic].contains(currentRank) {
                    Text("👑").font(.system(size: 22)).offset(y: -52)
                }
                
                Text(currentRank.shortName)
                    .font(.system(size: 13, weight: .bold)).foregroundColor(currentRank.color).tracking(2)
                    .padding(.horizontal, 12).padding(.vertical, 4).background(Capsule().fill(currentRank.color.opacity(0.15)))
                
                Text(currentRank.rawValue).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(currentRank.tagline).font(.system(size: 12)).foregroundColor(.gray).italic()
                Text("Level \(manager.userRankData.level)").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text("Top \(manager.userRankData.percentile)%").font(.system(size: 11)).foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.2)).frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [currentRank.color.opacity(0.8), currentRank.color.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(6, geo.size.width * CGFloat(min(max(Double(xpInRank)/Double(xpRange), 0), 1))), height: 6)
                        }
                    }.frame(height: 6)
                    HStack {
                        Text("\(manager.userRankData.totalXP) / \(nextRank?.xpRequired ?? currentRank.xpRequired * 2) XP").font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                        Spacer()
                        if let next = nextRank {
                            Text("Còn \(next.xpRequired - manager.userRankData.totalXP) XP để lên \(next.shortName)").font(.system(size: 11)).foregroundColor(currentRank.color.opacity(0.7))
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(minHeight: 320)
    }
    
    var timelineView: some View {
        let currentRank = manager.userRankData.currentRank
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(Rank.allCases.enumerated()), id: \.element) { index, rank in
                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(rank == currentRank ? rank.color.opacity(0.2) : .white.opacity(0.03))
                                    .frame(width: 48, height: 48)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(rank == currentRank ? rank.color.opacity(0.5) : .white.opacity(0.08), lineWidth: rank == currentRank ? 2 : 0.5))
                                // Mini cat face placeholder using circle
                                Circle()
                                    .fill(rank.color.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                Circle().fill(.white.opacity(0.6)).frame(width: 4, height: 4).offset(x: -4, y: -2)
                                Circle().fill(.white.opacity(0.6)).frame(width: 4, height: 4).offset(x: 4, y: -2)
                            }
                            Text(rank.shortName).font(.system(size: 8, weight: rank == currentRank ? .bold : .regular)).foregroundColor(rank == currentRank ? rank.color : .gray)
                            Text("Lv\(rank.level)").font(.system(size: 7)).foregroundColor(.gray)
                        }
                        .frame(width: 56)
                        if index < Rank.allCases.count - 1 {
                            Rectangle().fill(rank.xpRequired < manager.userRankData.totalXP ? currentRank.color.opacity(0.5) : Color(white: 0.18)).frame(width: 16, height: 2)
                        }
                    }
                }
            }.padding(.horizontal, 12)
        }
    }
    
    var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AchievementCategory.allCases, id: \.self) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedCategory = cat }
                    } label: {
                        Text(cat.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedCategory == cat ? .white : .gray)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(selectedCategory == cat ? .white.opacity(0.15) : .white.opacity(0.05)))
                            .overlay(Capsule().stroke(selectedCategory == cat ? .white.opacity(0.2) : .clear, lineWidth: 0.5))
                    }
                }
            }
        }
    }
    
    var achievementGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(filteredAchievements) { ach in
                if let prog = manager.progress(for: ach.id) {
                    AchievementCard2(achievement: ach, progress: prog)
                        .onTapGesture { selectedAchievement = ach; showDetail = true }
                }
            }
        }
    }
}

// MARK: - Achievement Card (v2, no emoji, no SF Symbols)
struct AchievementCard2: View {
    let achievement: AchievementDefinition
    let progress: AchievementProgress
    
    var currentTier: AchievementTier? { achievement.currentTier(progress: progress.currentValue) }
    var nextTier: AchievementTier? { achievement.nextTier(progress: progress.currentValue) }
    var isCompleted: Bool { nextTier == nil }
    var tierColor: Color {
        guard let t = currentTier else { return .gray }
        let r = Double(t.tier) / Double(max(achievement.tiers.count, 1))
        return Color(red: 0.3 + 0.7 * r, green: 0.7 - 0.4 * r, blue: 0.9 - 0.3 * r)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            AchievementBadgeView(tier: currentTier?.tier ?? 1, maxTier: achievement.tiers.count, size: 56)
            
            Text(currentTier?.name ?? achievement.title)
                .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                .lineLimit(2).multilineTextAlignment(.center).frame(height: 36)
            
            if let next = nextTier {
                Text("\(progress.currentValue)/\(next.requirement)")
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(white: 0.2)).frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(LinearGradient(colors: [tierColor, tierColor.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * next.progress(current: progress.currentValue), height: 3)
                    }
                }.frame(height: 3).padding(.horizontal, 8)
            } else if isCompleted {
                Text("✦ MAX")
                    .font(.system(size: 10, weight: .bold)).foregroundColor(tierColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(tierColor.opacity(0.12)))
            } else {
                Text(achievement.tiers.first?.description ?? "")
                    .font(.system(size: 11)).foregroundColor(.gray)
            }
        }
        .padding(14).frame(height: 175).frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.5))
        .shadow(color: isCompleted ? tierColor.opacity(0.12) : .black.opacity(0.3), radius: 10, y: 5)
    }
}