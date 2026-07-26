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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HÀNH TRÌNH CỦA BẠN")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .padding(.leading, 4)
            
            // Sử dụng GeometryReader để tính toán đường nối một cách thông minh
            GeometryReader { geometry in
                let width = geometry.size.width
                let badgeWidth: CGFloat = 44
                let totalBadges = stages.count
                // Khoảng cách giữa tâm các badge nếu chia đều chiều rộng
                let spacing = (width - (CGFloat(totalBadges) * badgeWidth)) / CGFloat(totalBadges - 1)
                
                ZStack(alignment: .topLeading) {
                    // 1. Vẽ đường nối nét đứt (nằm chính giữa tất cả cột mốc, trừ cái cuối)
                    ForEach(0..<stages.count - 1, id: \.self) { index in
                        let isActiveOrCompleted = stages[index].isUnlocked || stages[index+1].isUnlocked
                        
                        Rectangle()
                            .fill(Color.white.opacity(isActiveOrCompleted ? 0.15 : 0.05))
                            .frame(width: spacing, height: 1)
                            // Công thức offset: (số thứ tự cột tiếp theo * (badgeWidth + spacing)) - (spacing / 2)
                            .offset(x: (CGFloat(index + 1) * (badgeWidth + spacing)) - (spacing / 2),
                                    y: 22) // Căn chỉnh độ cao ngang tâm badge (44/2)
                    }
                    
                    // 2. Vẽ các Badge và Text
                    HStack(spacing: spacing) {
                        ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                            let isActive = stage.isUnlocked && stage.title == "Pro Watcher"
                            let isCompleted = stage.isUnlocked && stage.title != "Pro Watcher"
                            
                            VStack(spacing: 6) {
                                // Badge Button
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
                                                isCompleted ? Color(red: 0.1, green: 0.1, blue: 0.1) :
                                                Color(red: 0.06, green: 0.06, blue: 0.06)
                                            )
                                            .frame(width: badgeWidth, height: 48)
                                        
                                        // Viền
                                        HexagonShape()
                                            .stroke(
                                                isActive ? Color.white :
                                                isCompleted ? Color.white.opacity(0.25) :
                                                Color.white.opacity(0.05),
                                                lineWidth: isActive ? 2 : 1
                                            )
                                            .frame(width: badgeWidth, height: 48)
                                        
                                        // Icon
                                        Image(systemName: stage.iconName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(
                                                isActive ? .white :
                                                isCompleted ? .white.opacity(0.8) :
                                                .white.opacity(0.1)
                                            )
                                        
                                        // Glow Active
                                        if isActive {
                                            HexagonShape()
                                                .stroke(Color.white.opacity(0.25), lineWidth: 4)
                                                .blur(radius: 6)
                                                .frame(width: badgeWidth, height: 48)
                                        }
                                    }
                                    .scaleEffect(selectedID == stage.id ? 1.1 : 1.0)
                                }
                                .buttonStyle(.plain)
                                
                                // Text Labels
                                VStack(spacing: 0) {
                                    Text(stage.title)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .fixedSize(horizontal: true) // Ngăn không cho text bị ép co lại
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
                            .frame(width: 60) // Khung cột cố định để chứa đủ text
                        }
                    }
                }
                .frame(height: 100)
            }
            .frame(height: 100) // Đặt chiều cao cố định cho GeometryReader
            .padding(.horizontal, 16)
        }
    }
}