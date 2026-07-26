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
    
    // MARK: - Header
    var headerView: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Text("←")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 0.5))
                    )
            }
            
            Text("Danh Hiệu")
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(manager.userRankData.unlockedAchievements)/\(manager.userRankData.totalAchievements)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Rank Card
    var rankCard: some View {
        let currentRank = manager.userRankData.currentRank
        let nextRank = manager.userRankData.nextRank
        let xpInRank = manager.userRankData.totalXP - currentRank.xpRequired
        let xpRange = max((nextRank?.xpRequired ?? currentRank.xpRequired * 2) - currentRank.xpRequired, 1)
        
        return ZStack {
            Circle()
                .fill(currentRank.glowColor)
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(y: -20)
            
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [currentRank.color.opacity(0.3), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            VStack(spacing: 14) {
                ZStack {
                    // Custom shield badge
                    ShieldBadge(rank: currentRank)
                    
                    if [Rank.master, Rank.legend, Rank.mythic].contains(currentRank) {
                        Text("👑")
                            .font(.system(size: 22))
                            .offset(y: -52)
                            .shadow(color: currentRank.color.opacity(0.6), radius: 8)
                    }
                }
                
                Text(currentRank.shortName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(currentRank.color)
                    .tracking(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(currentRank.color.opacity(0.15)))
                
                Text(currentRank.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(currentRank.tagline)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .italic()
                
                Text("Level \(manager.userRankData.level)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Top \(manager.userRankData.percentile)% người dùng")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(white: 0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [currentRank.color.opacity(0.8), currentRank.color.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(6, geo.size.width * CGFloat(min(max(Double(xpInRank) / Double(xpRange), 0), 1))), height: 6)
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: xpInRank)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack {
                        Text("\(manager.userRankData.totalXP) / \(nextRank?.xpRequired ?? currentRank.xpRequired * 2) XP")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if let next = nextRank {
                            Text("Còn \(next.xpRequired - manager.userRankData.totalXP) XP để lên \(next.shortName)")
                                .font(.system(size: 11))
                                .foregroundColor(currentRank.color.opacity(0.7))
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(minHeight: 300)
    }
    
    // MARK: - Timeline
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(rank == currentRank ? rank.color.opacity(0.5) : .white.opacity(0.08), lineWidth: rank == currentRank ? 2 : 0.5)
                                    )
                                
                                Text(rank.badgeEmoji)
                                    .font(.system(size: 24))
                                    .opacity(rank.xpRequired <= manager.userRankData.totalXP ? 1.0 : 0.25)
                            }
                            
                            Text(rank.shortName)
                                .font(.system(size: 8, weight: rank == currentRank ? .bold : .regular))
                                .foregroundColor(rank == currentRank ? rank.color : .gray)
                                .lineLimit(1)
                            
                            Text("Lv\(rank.level)")
                                .font(.system(size: 7))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 56)
                        
                        if index < Rank.allCases.count - 1 {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(rank.xpRequired < manager.userRankData.totalXP ? currentRank.color.opacity(0.5) : Color(white: 0.18))
                                    .frame(width: 16, height: 2)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Category Filter
    var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedCategory == category ? .white : .gray)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? .white.opacity(0.15) : .white.opacity(0.05))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedCategory == category ? .white.opacity(0.2) : .clear, lineWidth: 0.5)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Achievement Grid
    var achievementGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(filteredAchievements) { achievement in
                if let prog = manager.progress(for: achievement.id) {
                    AchievementCard(
                        achievement: achievement,
                        progress: prog,
                        currentRank: manager.userRankData.currentRank
                    )
                    .onTapGesture {
                        selectedAchievement = achievement
                        showDetail = true
                    }
                }
            }
        }
    }
}

// MARK: - Custom Shield Badge
struct ShieldBadge: View {
    let rank: Rank
    
    var body: some View {
        ZStack {
            // Shield shape using RoundedRectangle with custom look
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [rank.color.opacity(0.15), rank.color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 90, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [rank.color.opacity(0.5), rank.color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: rank.glowColor, radius: 12)
            
            // Cat emoji
            Text(rank.badgeEmoji)
                .font(.system(size: 50))
                .shadow(color: rank.color.opacity(0.5), radius: 15)
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: AchievementDefinition
    let progress: AchievementProgress
    let currentRank: Rank
    
    var body: some View {
        let currentTier = achievement.currentTier(progress: progress.currentValue)
        let nextTier = achievement.nextTier(progress: progress.currentValue)
        let isCompleted = nextTier == nil
        let tierColor: Color = {
            guard let tier = currentTier else { return .gray }
            let ratio = Double(tier.tier) / Double(max(achievement.tiers.count, 1))
            return Color(red: 0.3 + 0.7 * ratio, green: 0.7 - 0.4 * ratio, blue: 0.9 - 0.3 * ratio)
        }()
        
        VStack(spacing: 10) {
            // Custom shield for achievement
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isCompleted ? tierColor.opacity(0.12) : .white.opacity(0.04))
                    .frame(width: 56, height: 62)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isCompleted ? tierColor.opacity(0.35) : .white.opacity(0.08), lineWidth: 1.5)
                    )
                    .shadow(color: isCompleted ? tierColor.opacity(0.15) : .clear, radius: 8)
                
                Text(currentTier?.icon ?? achievement.icon)
                    .font(.system(size: 32))
                    .opacity(currentTier != nil ? 1.0 : 0.3)
            }
            
            Text(currentTier?.name ?? achievement.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 36)
            
            if let next = nextTier {
                Text("\(progress.currentValue)/\(next.requirement)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.2))
                            .frame(height: 3)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [tierColor, tierColor.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * next.progress(current: progress.currentValue), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 8)
            } else if isCompleted {
                HStack(spacing: 4) {
                    Text("✔")
                        .font(.system(size: 10))
                        .foregroundColor(tierColor)
                    Text("MAX")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(tierColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(tierColor.opacity(0.12)))
            } else {
                Text(achievement.tiers.first?.description ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .frame(height: 175)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.12), .white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: isCompleted ? tierColor.opacity(0.12) : .black.opacity(0.3), radius: 10, y: 5)
    }
}