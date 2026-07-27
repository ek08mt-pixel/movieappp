import SwiftUI

struct AchievementTimelineRow: View {
    let stages: [JourneyStage]
    @State private var selectedID: UUID?
    
    private let badgeSize: CGFloat = 44
    private let spacing: CGFloat = 6
    
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
                                .fill(stages[i + 1].isUnlocked ? Color.white.opacity(0.3) : Color.white.opacity(0.05))
                                .frame(width: 10, height: 2)
                        }
                    }
                    .offset(y: badgeSize / 2)
                    
                    // Icons
                    HStack(spacing: spacing) {
                        ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                            let isActive = stage.isUnlocked && stage.title == "Pro Watcher"
                            let isCompleted = stage.isUnlocked && stage.title != "Pro Watcher"
                            
                            VStack(spacing: 8) {
                                Button(action: { withAnimation(.spring()) { selectedID = stage.id } }) {
                                    ZStack {
                                        if isActive {
                                            HexagonShape()
                                                .fill(Color.cyan.opacity(0.3))
                                                .frame(width: badgeSize + 6, height: badgeSize + 10)
                                                .blur(radius: 8)
                                        }
                                        
                                        HexagonShape()
                                            .fill(
                                                isCompleted ? Color.white.opacity(0.08) :
                                                    isActive ? Color.cyan.opacity(0.15) :
                                                    Color.white.opacity(0.03)
                                            )
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                        
                                        HexagonShape()
                                            .stroke(
                                                isActive ? Color.cyan.opacity(0.7) :
                                                    isCompleted ? Color.white.opacity(0.3) :
                                                    Color.white.opacity(0.06),
                                                lineWidth: isActive ? 2 : 1
                                            )
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                        
                                        CatShape()
                                            .fill(
                                                isActive ? Color.cyan :
                                                    isCompleted ? Color.white.opacity(0.6) :
                                                    Color.white.opacity(0.12)
                                            )
                                            .frame(width: 20, height: 20)
                                    }
                                    .scaleEffect(selectedID == stage.id ? 1.08 : 1.0)
                                }
                                .buttonStyle(.plain)
                                
                                VStack(spacing: 2) {
                                    Text(stage.title)
                                        .font(.system(size: 10, weight: isActive ? .bold : .medium, design: .rounded))
                                        .foregroundColor(
                                            isActive ? .cyan :
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