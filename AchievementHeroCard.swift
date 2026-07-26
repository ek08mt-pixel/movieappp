//
//  AchievementHeroCard.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

struct AchievementHeroCard: View {
    @State private var progressAnimation: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            // Avatar Hexagon
            ZStack {
                // Outer Glow (Lớp sáng lan tỏa)
                HexagonShape()
                    .stroke(Color.white.opacity(0.4), lineWidth: 4)
                    .blur(radius: 10)
                    .frame(width: 80, height: 88)
                
                // Inner Base
                HexagonShape()
                    .fill(
                        LinearGradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 80, height: 88)
                
                // Viền chính sáng
                HexagonShape()
                    .stroke(
                        LinearGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
                    .frame(width: 80, height: 88)
                
                // Icon (Sẽ thay bằng SVG sau)
                Image(systemName: "cat.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
            }
            
            // Text Info
            VStack(alignment: .leading, spacing: 8) {
                // Level Badge
                Text("Lv. 12")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                
                Text("Pro Watcher")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Top 18% người xem tích cực")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                
                Spacer().frame(height: 4)
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 4)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 120 * progressAnimation, height: 4)
                    }
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.6)) { progressAnimation = 0.65 }
                    }
                    
                    HStack(spacing: 0) {
                        Text("2,350 / 3,600 XP")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                        Spacer()
                        Text("Còn 1,250 XP để lên cấp tiếp theo")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                    }
                }
            }
            Spacer()
        }
        .padding(24)
        .background(
            // Lớp nền Glassmorphism Depth
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                .shadow(color: Color.white.opacity(0.05), radius: 1, x: 0, y: 1)
        )
        .overlay(
            // Viền ngoài đứt đoạn (Dashed) và sáng
            RoundedRectangle(cornerRadius: 24)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                .foregroundColor(
                    LinearGradient(
                        stops: [.init(color: .white.opacity(0.8), location: 0.2), .init(color: .white.opacity(0.1), location: 0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        // Outer Glow (Lớp viền mờ chạy quanh)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.15), lineWidth: 4)
                .blur(radius: 6)
        )
        .padding(1)
    }
}