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
            // 1. Avatar Hexagon - Thu nhỏ để cân đối
            ZStack {
                HexagonShape()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .blur(radius: 10)
                    .frame(width: 80, height: 88)
                
                HexagonShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.08, green: 0.08, blue: 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 88)
                
                HexagonShape()
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 80, height: 88)
                
                // Icon
                Image(systemName: "cat.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
            }
            
            // 2. Text Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Lv. 12")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                    Spacer()
                }
                
                Text("Pro Watcher")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Top 18% người xem tích cực")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                
                Spacer().frame(height: 4)
                
                // 3. Progress Bar
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
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
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 8)
        )
    }
}