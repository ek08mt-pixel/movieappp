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
        VStack(alignment: .leading, spacing: 20) {
            Text("HÀNH TRÌNH CỦA BẠN")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .padding(.leading, 8)
            
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                    let isActive = stage.isUnlocked && stage.title == "Pro Watcher"
                    let isCompleted = stage.isUnlocked && stage.title != "Pro Watcher"
                    let isLocked = !stage.isUnlocked
                    
                    ZStack(alignment: .top) {
                        // Đường nét đứt nối (Chạy dưới, trừ cái cuối cùng)
                        if index < stages.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 52, height: 1.5)
                                .offset(x: 26, y: 26)
                        }
                        
                        VStack(spacing: 12) {
                            // Badge
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    selectedID = stage.id
                                }
                                // Xử lý tương tác ở đây
                            }) {
                                ZStack {
                                    // Background Hexagon
                                    HexagonShape()
                                        .fill(
                                            isActive ? Color.white.opacity(0.15) :
                                            isCompleted ? Color(red: 0.12, green: 0.12, blue: 0.12) :
                                            Color(red: 0.06, green: 0.06, blue: 0.06)
                                        )
                                        .frame(width: 56, height: 64)
                                    
                                    // Border
                                    HexagonShape()
                                        .stroke(
                                            isActive ? Color.white :
                                            isCompleted ? Color.white.opacity(0.3) :
                                            Color.white.opacity(0.05),
                                            lineWidth: isActive ? 2 : 1
                                        )
                                        .frame(width: 56, height: 64)
                                    
                                    // Icon (SF Symbol tạm thời)
                                    Image(systemName: stage.iconName)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(
                                            isActive ? .white :
                                            isCompleted ? .white.opacity(0.8) :
                                            .white.opacity(0.15)
                                        )
                                    
                                    // Active Glow Ring
                                    if isActive {
                                        HexagonShape()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 6)
                                            .blur(radius: 12)
                                            .frame(width: 56, height: 64)
                                    }
                                }
                                .scaleEffect(selectedID == stage.id ? 1.05 : 1.0)
                            }
                            .buttonStyle(.plain) // Ngăn hiệu ứng click mặc định của SwiftUI
                            
                            // Text Labels
                            VStack(spacing: 2) {
                                Text(stage.title)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(
                                        isActive ? .white :
                                        isCompleted ? Color(red: 0.65, green: 0.65, blue: 0.65) :
                                        Color(red: 0.35, green: 0.35, blue: 0.35)
                                    )
                                Text(stage.level)
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                                    .foregroundColor(
                                        isActive ? Color(red: 0.65, green: 0.65, blue: 0.65) :
                                        isCompleted ? Color(red: 0.45, green: 0.45, blue: 0.45) :
                                        Color(red: 0.25, green: 0.25, blue: 0.25)
                                    )
                            }
                        }
                    }
                    .frame(width: 70) // Chiều rộng cố định mỗi cột để các mốc thẳng hàng chuẩn xác
                }
            }
            .padding(.horizontal, 4)
        }
    }
}