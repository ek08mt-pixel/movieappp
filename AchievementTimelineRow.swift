import SwiftUI

struct AchievementTimelineRow: View {
    let stages: [JourneyStage]
    @StateObject private var manager = AchievementManager.shared
    @State private var selectedID: UUID?
    
    private let badgeSize: CGFloat = 44
    private let spacing: CGFloat = 6
    
    func rankForTitle(_ title: String) -> Rank {
        Rank.allCases.first(where: { $0.rawValue == title }) ?? .newbie
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HÀNH TRÌNH CỦA BẠN")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .top) {
                    // Đường nối
                    HStack(spacing: spacing) {
                        ForEach(0..<stages.count - 1, id: \.self) { i in
                            Rectangle()
                                .fill(stages[i].isUnlocked ? manager.userRankData.currentRank.color.opacity(0.4) : Color.white.opacity(0.06))
                                .frame(width: 10, height: 2)
                        }
                    }
                    .offset(y: badgeSize / 2)
                    
                    // Icons
                    HStack(spacing: spacing) {
                        ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                            let rank = rankForTitle(stage.title)
                            let isCurrent = rank == manager.userRankData.currentRank
                            let isCompleted = stage.isUnlocked && !isCurrent
                            
                            VStack(spacing: 8) {
                                Button(action: { withAnimation(.spring()) { selectedID = stage.id } }) {
                                    ZStack {
                                        if isCurrent {
                                            HexagonShape()
                                                .fill(rank.glowColor)
                                                .frame(width: badgeSize + 6, height: badgeSize + 10)
                                                .blur(radius: 8)
                                        }
                                        
                                        HexagonShape()
                                            .fill(
                                                isCompleted ? rank.color.opacity(0.15) :
                                                    isCurrent ? rank.color.opacity(0.25) :
                                                    Color(white: 0.06)
                                            )
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                        
                                        HexagonShape()
                                            .stroke(
                                                isCurrent ? rank.color.opacity(0.8) :
                                                    isCompleted ? rank.color.opacity(0.4) :
                                                    Color.white.opacity(0.06),
                                                lineWidth: isCurrent ? 2 : 1
                                            )
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                        
                                        CatShape()
                                            .fill(
                                                isCurrent ? rank.color :
                                                    isCompleted ? rank.color.opacity(0.7) :
                                                    Color.white.opacity(0.12)
                                            )
                                            .frame(width: 20, height: 20)
                                    }
                                    .scaleEffect(selectedID == stage.id ? 1.08 : 1.0)
                                }
                                .buttonStyle(.plain)
                                
                                VStack(spacing: 2) {
                                    Text(stage.title)
                                        .font(.system(size: 10, weight: isCurrent ? .bold : .medium, design: .rounded))
                                        .foregroundColor(
                                            isCurrent ? rank.color :
                                                isCompleted ? .white.opacity(0.7) :
                                                .white.opacity(0.25)
                                        )
                                    Text(stage.level)
                                        .font(.system(size: 9, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
}