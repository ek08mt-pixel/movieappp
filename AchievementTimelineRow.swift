//
//  AchievementTimelineRow.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

struct AchievementTimelineRow: View {
    let stages: [JourneyStage]
    @State private var selectedID: UUID?
    
    private let badgeSize: CGFloat = 44
    private let columnWidth: CGFloat = 64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HÀNH TRÌNH CỦA BẠN")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .padding(.leading, 4)
            
            ZStack(alignment: .topLeading) {
                // 1. Vẽ đường nối nét đứt
                // Tính khoảng cách giữa tâm 2 cột liền kề: ColumnWidth - (BadgeSize/2) + (BadgeSize/2) = ColumnWidth
                ForEach(0..<stages.count - 1, id: \.self) { index in
                    let isActiveOrCompleted = stages[index].isUnlocked || stages[index+1].isUnlocked
                    
                    Rectangle()
                        .fill(Color.white.opacity(isActiveOrCompleted ? 0.2 : 0.05))
                        .frame(width: columnWidth - badgeSize, height: 1)
                        .offset(x: (CGFloat(index + 1) * columnWidth) - (badgeSize / 2) - (columnWidth/2),
                                y: badgeSize / 2)
                }
                
                // 2. Vẽ các cột mốc
                HStack(spacing: columnWidth - badgeSize) {
                    ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                        let isActive = stage.isUnlocked && stage.title == "Pro Watcher"
                        let isCompleted = stage.isUnlocked && stage.title != "Pro Watcher"
                        
                        VStack(spacing: 8) {
                            // Badge
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedID = stage.id
                                }
                            }) {
                                ZStack {
                                    // Nền
                                    HexagonShape()
                                        .fill(
                                            isActive ? Color(red: 0.18, green: 0.18, blue: 0.18) :
                                            isCompleted ? Color(red: 0.08, green: 0.08, blue: 0.08) :
                                            Color(red: 0.04, green: 0.04, blue: 0.04)
                                        )
                                        .frame(width: badgeSize, height: badgeSize + 4)
                                    
                                    // Viền
                                    HexagonShape()
                                        .stroke(
                                            isActive ? Color.white :
                                            isCompleted ? Color.white.opacity(0.3) :
                                            Color.white.opacity(0.05),
                                            lineWidth: isActive ? 2 : 1
                                        )
                                        .frame(width: badgeSize, height: badgeSize + 4)
                                    
                                    // Icon
                                    Image(systemName: stage.iconName)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(
                                            isActive ? .white :
                                            isCompleted ? .white.opacity(0.8) :
                                            .white.opacity(0.1)
                                        )
                                    
                                    // Active Glow
                                    if isActive {
                                        HexagonShape()
                                            .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                            .blur(radius: 6)
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                    }
                                }
                                .scaleEffect(selectedID == stage.id ? 1.08 : 1.0)
                            }
                            .buttonStyle(.plain)
                            
                            // Text bên dưới
                            VStack(spacing: 2) {
                                Text(stage.title)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .fixedSize(horizontal: true, vertical: false)
                                    .foregroundColor(
                                        isActive ? .white :
                                        isCompleted ? Color(red: 0.6, green: 0.6, blue: 0.6) :
                                        Color(red: 0.3, green: 0.3, blue: 0.3)
                                    )
                                Text(stage.level)
                                    .font(.system(size: 9, weight: .regular, design: .rounded))
                                    .foregroundColor(
                                        isActive ? Color(red: 0.5, green: 0.5, blue: 0.5) :
                                        isCompleted ? Color(red: 0.4, green: 0.4, blue: 0.4) :
                                        Color(red: 0.2, green: 0.2, blue: 0.2)
                                    )
                            }
                        }
                        .frame(width: columnWidth)
                    }
                }
            }
            .frame(height: 110) // Chiều cao cố định cho toàn bộ Timeline
            .padding(.horizontal, 0) // Không padding ngang để dàn trang đều
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}