//
//  AchievementTimelineRow.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

struct AchievementTimelineRow: View {
    let stages: [JourneyStage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HÀNH TRÌNH CỦA BẠN")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(.textSecondary)
            
            // Timeline
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                    // Một cột mốc (Icon + Tên)
                    VStack(spacing: 10) {
                        ZStack {
                            // Đường nét đứt nối liền các cột (trừ cái cuối cùng)
                            if index < stages.count - 1 {
                                HStack(spacing: 0) {
                                    Spacer()
                                    // Vẽ đường nét đứt
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: 40, y: 0))
                                    }
                                    .stroke(
                                        style: StrokeStyle(
                                            lineWidth: 1.5,
                                            dash: [4, 4]
                                        )
                                    )
                                    .foregroundColor(stage.isUnlocked ? Color.white.opacity(0.3) : Color.white.opacity(0.05))
                                    .frame(width: 42, height: 1)
                                    Spacer()
                                }
                                .offset(y: -22) // Căn chỉnh đường nét ngang tâm hình
                            }
                            
                            // Icon Hexagon
                            let iconShape = stage.getIconShape()
                            
                            ZStack {
                                // Nền tối / Sáng
                                HexagonShape()
                                    .fill(stage.isUnlocked ? Color(red: 0.16, green: 0.16, blue: 0.16) : Color(red: 0.08, green: 0.08, blue: 0.08))
                                    .frame(width: 44, height: 48)
                                
                                // Viền (Outline)
                                HexagonShape()
                                    .stroke(stage.isUnlocked ? Color.white.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
                                    .frame(width: 44, height: 48)
                                
                                // Nội dung Shape
                                AnyView(iconShape)
                                    .fill(stage.isUnlocked ? Color.white : Color.white.opacity(0.15))
                                    .frame(width: 20, height: 20)
                            }
                            // Glow ring cho cột đang mở
                            .overlay(
                                Group {
                                    if stage.isUnlocked {
                                        HexagonShape()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 3)
                                            .blur(radius: 6)
                                            .frame(width: 44, height: 48)
                                    }
                                }
                            )
                        }
                        .frame(width: 50)
                        
                        // Tên & Cấp độ (Text bên dưới)
                        VStack(spacing: 2) {
                            Text(stage.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(stage.isUnlocked ? .textSecondary : .textTertiary)
                            
                            Text(stage.level)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(stage.isUnlocked ? .textSecondary : .textTertiary)
                        }
                        .frame(width: 70)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        AchievementTimelineRow(stages: [
            JourneyStage(title: "Newbie", level: "Lv.1", isUnlocked: true),
            JourneyStage(title: "Enthusiast", level: "Lv.5", isUnlocked: true),
            JourneyStage(title: "Fanatic", level: "Lv.10", isUnlocked: true),
            JourneyStage(title: "Pro Watcher", level: "Lv.12", isUnlocked: true),
            JourneyStage(title: "Master", level: "Lv.15", isUnlocked: false),
            JourneyStage(title: "Legend", level: "Lv.20", isUnlocked: false)
        ])
    }
}