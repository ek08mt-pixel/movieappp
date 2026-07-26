import SwiftUI

struct AchievementView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: AchievementCategory = .all
    @State private var userRank = AchievementMockData.userRankData
    @State private var progress = AchievementMockData.userProgress
    @State private var selectedAchievement: AchievementDefinition?
    @State private var showDetail = false
    @Namespace private var animation
    
    private let achievements = AchievementMockData.achievements
    
    var filteredAchievements: [AchievementDefinition] {
        if selectedCategory == .all { return achievements }
        return achievements.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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
                        // Header
                        headerView
                            .padding(.top, 60)
                        
                        // Rank Card
                        rankCard
                            .padding(.horizontal, 20)
                        
                        // Timeline
                        timelineView
                            .padding(.horizontal, 20)
                        
                        // Category Filter
                        categoryFilter
                            .padding(.horizontal, 20)
                        
                        // Achievement Grid
                        achievementGrid
                            .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDetail) {
                if let achievement = selectedAchievement,
                   let prog = progress.first(where: { $0.achievementId == achievement.id }) {
                    AchievementDetailView(
                        achievement: achievement,
                        progress: prog,
                        userRank: userRank
                    )
                }
            }
        }
    }
    
    // MARK: - Header
    var headerView: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 0.5))
                    )
            }
            
            Text("Danh hiệu")
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                // Info action
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Rank Card
    var rankCard: some View {
        let currentRank = userRank.currentRank
        let nextRank = userRank.nextRank
        let xpInRank = userRank.totalXP - currentRank.xpRequired
        let xpRange = (nextRank?.xpRequired ?? currentRank.xpRequired * 2) - currentRank.xpRequired
        
        return ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: currentRank.color.opacity(0.1), radius: 30, y: 10)
            
            VStack(spacing: 16) {
                // Icon
                Text(currentRank.icon)
                    .font(.system(size: 48))
                    .shadow(color: currentRank.color.opacity(0.3), radius: 20)
                
                // Title
                Text(currentRank.rawValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Level
                Text("Level \(userRank.level)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(currentRank.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(currentRank.color.opacity(0.15))
                    )
                
                // Percentile
                Text("Top \(userRank.percentile)% người dùng")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                // XP Bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(white: 0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [currentRank.color.opacity(0.8), currentRank.color.opacity(0.4)],
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
                        Text("\(userRank.totalXP) / \(nextRank?.xpRequired ?? currentRank.xpRequired * 2) XP")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if let next = nextRank {
                            Text("Còn \(next.xpRequired - userRank.totalXP) XP để lên \(next.rawValue)")
                                .font(.system(size: 11))
                                .foregroundColor(currentRank.color.opacity(0.7))
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(height: 220)
    }
    
    // MARK: - Timeline
    var timelineView: some View {
        let currentRank = userRank.currentRank
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(Rank.allCases.enumerated()), id: \.element) { index, rank in
                    HStack(spacing: 0) {
                        // Node
                        VStack(spacing: 6) {
                            Text(rank.icon)
                                .font(.system(size: 22))
                                .opacity(rank.xpRequired <= userRank.totalXP ? 1.0 : 0.3)
                            
                            Text(rank.rawValue)
                                .font(.system(size: 8))
                                .foregroundColor(rank == currentRank ? currentRank.color : .gray)
                                .lineLimit(1)
                            
                            Text("Lv\(rank.level)")
                                .font(.system(size: 7))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(rank == currentRank ? currentRank.color.opacity(0.12) : .clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(rank == currentRank ? currentRank.color.opacity(0.3) : .clear, lineWidth: 1)
                                )
                        )
                        
                        // Connector
                        if index < Rank.allCases.count - 1 {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(rank.xpRequired < userRank.totalXP ? currentRank.color.opacity(0.4) : Color(white: 0.2))
                                    .frame(width: 20, height: 2)
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
                if let prog = progress.first(where: { $0.achievementId == achievement.id }) {
                    AchievementCard(
                        achievement: achievement,
                        progress: prog,
                        namespace: animation
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

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: AchievementDefinition
    let progress: AchievementProgress
    var namespace: Namespace.ID
    
    var body: some View {
        let currentTier = achievement.currentTier(progress: progress.currentValue)
        let nextTier = achievement.nextTier(progress: progress.currentValue)
        let isCompleted = nextTier == nil
        
        VStack(spacing: 10) {
            // Icon
            Text(currentTier?.icon ?? achievement.icon)
                .font(.system(size: 36))
                .frame(height: 44)
                .opacity(currentTier != nil ? 1.0 : 0.3)
            
            // Title
            Text(currentTier?.name ?? achievement.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 36)
            
            // Description
            if let next = nextTier {
                Text("\(progress.currentValue) / \(next.requirement)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
                
                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.2))
                            .frame(height: 3)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.5))
                            .frame(width: geo.size.width * next.progress(current: progress.currentValue), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 8)
            } else if isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green.opacity(0.8))
                    Text("Đã đạt")
                        .font(.system(size: 11))
                        .foregroundColor(.green.opacity(0.8))
                }
            } else {
                Text(achievement.tiers.first?.description ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .frame(height: 170)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}