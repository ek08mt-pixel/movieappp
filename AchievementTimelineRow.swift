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
    
    func iconForStage(_ title: String) -> String {
        switch title {
        case "Newbie": return crownIconSVG
        case "Enthusiast": return lightningIconSVG
        case "Fanatic": return flameIconSVG
        case "Pro Watcher": return catIconSVG
        case "Master": return crownIconSVG
        case "Legend": return crownIconSVG
        default: return crownIconSVG
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
                    // 1. Đường gạch nối `---`
                    HStack(spacing: spacing + badgeSize) {
                        ForEach(0..<stages.count - 1, id: \.self) { index in
                            let nextIsActive = stages[index + 1].isUnlocked
                            Rectangle()
                                .fill(Color.white.opacity(nextIsActive ? 0.2 : 0.05))
                                .frame(width: 10, height: 1.5)
                        }
                    }
                    .offset(y: 22)
                    
                    // 2. Các cột mốc
                    HStack(spacing: spacing) {
                        ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                            let isActive = stage.isUnlocked && stage.title == "Pro Watcher"
                            let isCompleted = stage.isUnlocked && stage.title != "Pro Watcher"
                            
                            VStack(spacing: 8) {
                                Button(action: { withAnimation(.spring()) { selectedID = stage.id } }) {
                                    ZStack {
                                        HexagonShape()
                                            .fill(
                                                isActive ? Color(red: 0.2, green: 0.2, blue: 0.2) :
                                                isCompleted ? Color(red: 0.1, green: 0.1, blue: 0.1) :
                                                Color(red: 0.04, green: 0.04, blue: 0.04)
                                            )
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                        
                                        HexagonShape()
                                            .stroke(isActive ? Color.white : (isCompleted ? Color.white.opacity(0.3) : Color.white.opacity(0.05)), lineWidth: isActive ? 2 : 1)
                                            .frame(width: badgeSize, height: badgeSize + 4)
                                        
                                        // Icon (Render từ Base64 String)
                                        Image(svgBase64: iconForStage(stage.title))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .opacity(isActive ? 1.0 : (isCompleted ? 0.8 : 0.1))
                                        
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
                                    Text(stage.title).font(.system(size: 10, weight: .medium, design: .rounded)).fixedSize(horizontal: true, vertical: false)
                                        .foregroundColor(isActive ? .white : (isCompleted ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color(red: 0.3, green: 0.3, blue: 0.3)))
                                    Text(stage.level).font(.system(size: 9, weight: .regular, design: .rounded))
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