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
        HStack(alignment: .center, spacing: 16) {
            // 1. Avatar Container (Hexagon + Cat + Sparkles)
            ZStack {
                // Outer Glow (Tỏa sáng xung quanh)
                HexagonShape()
                    .stroke(Color.white.opacity(0.4), lineWidth: 3)
                    .blur(radius: 10)
                    .frame(width: 88, height: 96)
                
                // Base Background (Gradient nền)
                HexagonShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 88, height: 96)
                
                // Viền sáng bao quanh (Rim Light)
                HexagonShape()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .white.opacity(0.1), .white.opacity(0.0), .white.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 88, height: 96)
                
                // Con mèo (Custom Shape)
                ProCatIcon()
                    .fill(Color.white)
                    .frame(width: 52, height: 52)
                    .shadow(color: .white.opacity(0.2), radius: 4, x: 0, y: 0)
                
                // Hạt lấp lánh (Sparkles) xung quanh mèo
                Circle().fill(Color.white.opacity(0.7)).frame(width: 3, height: 3).offset(x: -42, y: -30)
                Circle().fill(Color.white.opacity(0.4)).frame(width: 2, height: 2).offset(x: 38, y: -28)
                Circle().fill(Color.white.opacity(0.6)).frame(width: 4, height: 4).offset(x: -45, y: 18)
                Circle().fill(Color.white.opacity(0.3)).frame(width: 2, height: 2).offset(x: 42, y: 22)
                Circle().fill(Color.white.opacity(0.8)).frame(width: 2, height: 2).offset(x: -30, y: 42)
                Circle().fill(Color.white.opacity(0.5)).frame(width: 2, height: 2).offset(x: 30, y: 45)
            }
            
            // 2. Text Info
            VStack(alignment: .leading, spacing: 6) {
                Text("Lv. 12")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                
                Text("Pro Watcher")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Top 18% người xem tích cực")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                
                Spacer().frame(height: 2)
                
                // 3. Progress Bar
                VStack(alignment: .leading, spacing: 3) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(height: 5)
                        Capsule().fill(Color.white).frame(width: 110 * progressAnimation, height: 5)
                    }
                    .onAppear { withAnimation(.easeOut(duration: 0.6)) { progressAnimation = 0.65 } }
                    
                    HStack(spacing: 0) {
                        Text("2,350 / 3,600 XP").font(.system(size: 10, weight: .regular, design: .rounded)).foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                        Spacer()
                        Text("Còn 1,250 XP để lên cấp tiếp theo").font(.system(size: 10, weight: .regular, design: .rounded)).foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.12, green: 0.12, blue: 0.12)))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        stops: [.init(color: .white.opacity(0.3), location: 0.0), .init(color: .white.opacity(0.05), location: 0.4), .init(color: .clear, location: 0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.white.opacity(0.05), radius: 10, x: 0, y: 10)
    }
}