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
    private let spacing: CGFloat = 6
    
    func iconForStage(_ title: String) -> any Shape {
        switch title {
        case "Newbie": return CrownIcon()
        case "Enthusiast": return LightningIcon()
        case "Fanatic": return FlameIcon()
        case "Pro Watcher": return CatShape()
        case "Master": return CrownIcon()
        case "Legend": return CrownIcon()
        default: return CrownIcon()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HÀNH TRÌNH CỦA BẠN")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .padding(.leading, 4)
            
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .top) {
                    // Đường nối
                    HStack(spacing: spacing + badgeSize) {
                        ForEach(0..<stages.count - 1, id: \.self) { index in
                            let nextIsActive = stages[index + 1].isUnlocked
                            Rectangle()
                                .fill(Color.white.opacity(nextIsActive ? 0.2 : 0.05))
                                .frame(width: 10, height: 1.5)
                        }
                    }
                    .offset(y: 22)
                    
                    // Icon
                    HStack(spacing: spacing) {
                        ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                            let isActive = stage.isUnlocked && stage.title == "Pro Watcher"
                            let isCompleted = stage.isUnlocked && stage.title != "Pro Watcher"
                            
                            VStack(spacing: 8) {
                                Button(action: { withAnimation(.spring()) { selectedID = stage.id } }) {
                                    ZStack {
                                        // Nền Hexagon
                                        HexagonShape()
                                            .fill(isActive ? Color(red: 0.2, green: 0.2, blue: 0.2) : isCompleted ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.04, green: 0.04, blue: 0.04))
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                        
                                        HexagonShape()
                                            .stroke(isActive ? Color.white : (isCompleted ? Color.white.opacity(0.3) : Color.white.opacity(0.05)), lineWidth: isActive ? 2 : 1)
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                        
                                        // Render Icon Shape
                                        AnyShape(iconForStage(stage.title))
                                            .fill(isActive ? .white : (isCompleted ? .white.opacity(0.8) : .white.opacity(0.1)))
                                            .frame(width: 20, height: 20)
                                        
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
                                
                                VStack(spacing: 2) {
                                    Text(stage.title)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .fixedSize(horizontal: true, vertical: false)
                                        .foregroundColor(isActive ? .white : (isCompleted ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color(red: 0.3, green: 0.3, blue: 0.3)))
                                    Text(stage.level)
                                        .font(.system(size: 9, weight: .regular, design: .rounded))
                                        .foregroundColor(isActive ? Color(red: 0.5, green: 0.5, blue: 0.5) : (isCompleted ? Color(red: 0.4, green: 0.4, blue: 0.4) : Color(red: 0.2, green: 0.2, blue: 0.2)))
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