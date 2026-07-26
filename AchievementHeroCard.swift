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
                    .stroke(Color.white.opacity(0.25), lineWidth: 6)
                    .blur(radius: 12)
                    .frame(width: 82, height: 90)
                
                // Inner Base
                HexagonShape()
                    .fill(Color.black.opacity(0.6)) // Làm nền tối cho Avatar
                    .frame(width: 82, height: 90)
                
                // Viền chính
                HexagonShape()
                    .stroke(
                        LinearGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
                    .frame(width: 82, height: 90)
                
                // Inner Glow (Lớp viền mờ bên trong)
                HexagonShape()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .blur(radius: 3)
                    .frame(width: 82, height: 90)
                
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
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                
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
            // 1. Lớp nền Glassmorphism
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial.opacity(0.4)) // Nền kính mờ
                .environment(\.colorScheme, .dark) // Ép chế độ Dark cho material
        )
        .overlay(
            // 2. Viền ngoài siêu mỏng (White Blur đứt đoạn)
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.3), location: 0.0),
                            .init(color: .white.opacity(0.05), location: 0.3),
                            .init(color: .white.opacity(0.0), location: 0.7),
                            .init(color: .white.opacity(0.15), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        // 3. Bóng đổ để tách khỏi nền
        .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
    }
}