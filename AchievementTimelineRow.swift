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
    private let spacing: CGFloat = 12
    private let iconSize: CGFloat = 18
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HÀNH TRÌNH CỦA BẠN")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .padding(.leading, 4)
            
            // Đặt HStack vào trong 1 VStack căn giữa để luôn nằm chính giữa
            VStack(alignment: .center, spacing: 0) {
                HStack(spacing: spacing) {
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
                                    
                                    // SF Symbol
                                    Image(systemName: stage.iconName)
                                        .font(.system(size: iconSize, weight: .medium))
                                        .foregroundColor(
                                            isActive ? .white :
                                            isCompleted ? .white.opacity(0.8) :
                                            .white.opacity(0.1)
                                        )
                                    
                                    // Glow Active
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
                            
                            // Text Labels
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
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
    }
}