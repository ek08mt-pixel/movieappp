import SwiftUI

struct AchievementHeroCard: View {
    @State private var progressAnimation: CGFloat = 0
    @StateObject private var manager = AchievementManager.shared
    
    var currentRank: Rank {
        manager.userRankData.currentRank
    }
    
    var nextRank: Rank? {
        manager.userRankData.nextRank
    }
    
    var xpProgress: Double {
        let base = currentRank.xpRequired
        let next = nextRank?.xpRequired ?? base * 2
        return min(max(Double(manager.userRankData.totalXP - base) / Double(next - base), 0), 1)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Avatar - Hexagon với màu rank
            ZStack {
                // Glow
                HexagonShape()
                    .fill(currentRank.glowColor)
                    .frame(width: 90, height: 98)
                    .blur(radius: 16)
                
                HexagonShape()
                    .fill(
                        LinearGradient(
                            colors: [currentRank.color.opacity(0.2), Color(white: 0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 88, height: 96)
                
                HexagonShape()
                    .stroke(
                        LinearGradient(
                            colors: [currentRank.color.opacity(0.8), currentRank.color.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 88, height: 96)
                
                CatShape()
                    .fill(currentRank.color)
                    .frame(width: 40, height: 40)
                
                // Sparkles
                Circle().fill(.white.opacity(0.8)).frame(width: 3, height: 3).offset(x: -40, y: -28)
                Circle().fill(.white.opacity(0.5)).frame(width: 2, height: 2).offset(x: 36, y: -26)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Lv. \(manager.userRankData.level)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(currentRank.color)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(currentRank.color.opacity(0.15)))
                    .overlay(Capsule().stroke(currentRank.color.opacity(0.3), lineWidth: 0.5))
                
                Text(currentRank.rawValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Top \(manager.userRankData.percentile)% người xem")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                Spacer().frame(height: 2)
                
                VStack(alignment: .leading, spacing: 3) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 5)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [currentRank.color, currentRank.color.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 110 * progressAnimation, height: 5)
                    }
                    .onAppear { withAnimation(.easeOut(duration: 0.8)) { progressAnimation = xpProgress } }
                    
                    HStack(spacing: 0) {
                        Text("\(manager.userRankData.totalXP) / \(nextRank?.xpRequired ?? 0) XP")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.gray)
                        Spacer()
                        if let next = nextRank {
                            Text("Còn \(next.xpRequired - manager.userRankData.totalXP) XP → \(next.shortName)")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(white: 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            currentRank.color.opacity(0.5),
                            .white.opacity(0.15),
                            currentRank.color.opacity(0.3),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(currentRank.color.opacity(0.15), lineWidth: 4)
                .blur(radius: 6)
        )
        .shadow(color: currentRank.color.opacity(0.1), radius: 12, y: 6)
    }
}