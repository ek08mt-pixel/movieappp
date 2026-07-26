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
            
            // Hàng ngang
            HStack(spacing: -12) {
                ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                    let isActive = stage.isUnlocked && stage.title == "Pro Watcher"
                    let isCompleted = stage.isUnlocked && stage.title != "Pro Watcher"
                    
                    ZStack(alignment: .top) {
                        // Đường nối nét đứt (ẩn ở cái cuối cùng)
                        if index < stages.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(isActive || isCompleted ? 0.15 : 0.05))
                                .frame(width: 44, height: 1)
                                .offset(x: 22, y: 22)
                        }
                        
                        VStack(spacing: 6) {
                            // Badge Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedID = stage.id
                                }
                            }) {
                                ZStack {
                                    // Nền tối đa
                                    HexagonShape()
                                        .fill(
                                            isActive ? Color(red: 0.15, green: 0.15, blue: 0.15) :
                                            isCompleted ? Color(red: 0.1, green: 0.1, blue: 0.1) :
                                            Color(red: 0.06, green: 0.06, blue: 0.06)
                                        )
                                        .frame(width: 42, height: 48)
                                    
                                    // Viền nhẹ
                                    HexagonShape()
                                        .stroke(
                                            isActive ? Color.white :
                                            isCompleted ? Color.white.opacity(0.3) :
                                            Color.white.opacity(0.05),
                                            lineWidth: isActive ? 2 : 1
                                        )
                                        .frame(width: 42, height: 48)
                                    
                                    // Icon bên trong (đã scale nhỏ lại)
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
                                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                            .blur(radius: 8)
                                            .frame(width: 42, height: 48)
                                    }
                                }
                                .scaleEffect(selectedID == stage.id ? 1.1 : 1.0)
                            }
                            .buttonStyle(.plain)
                            
                            // Text Labels (Nhỏ gọn)
                            VStack(spacing: 0) {
                                Text(stage.title)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
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
                        .frame(width: 56) // Khung cột được giới hạn nhẹ, nhưng dùng spacing âm để đẩy sát vào nhau
                    }
                }
            }
            .padding(.top, 4)
            .padding(.horizontal, 4)
        }
    }
}