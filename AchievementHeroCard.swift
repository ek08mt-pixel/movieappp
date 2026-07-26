//
//  AchievementHeroCard.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

struct AchievementHeroCard: View {
    // Màu sắc đặc thù cho Component này
    private let cardBgColor = Color(red: 0.1, green: 0.1, blue: 0.1) // #1A1A1A
    private let progressBg = Color.white.opacity(0.15)
    private let progressFill = Color.white
    
    @State private var progressAnimation: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 24) {
                // 1. Avatar Hexagon
                ZStack {
                    // Outer Glow Layer (Hiệu ứng ánh sáng lan tỏa)
                    HexagonShape()
                        .stroke(Color.white.opacity(0.25), lineWidth: 6)
                        .blur(radius: 12)
                        .frame(width: 110, height: 120)
                    
                    // Inner Base Layer (Tạo chiều sâu Gradient)
                    HexagonShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.08, green: 0.08, blue: 0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 120)
                    
                    // Border Stroke (Sáng hơn)
                    HexagonShape()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 110, height: 120)
                    
                    // Tạm thời dùng SF Symbol để test layout, sau này thay = AnyShape(YourSVG)
                    Image(systemName: "cat.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
                .padding(.leading, 4)
                
                // 2. Text Info (Phần bên phải)
                VStack(alignment: .leading, spacing: 10) {
                    // Level Badge
                    Text("Lv. 12")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    
                    // Title (Font tròn, lớn)
                    Text("Pro Watcher")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Subtitle
                    Text("Top 18% người xem tích cực")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                    
                    Spacer().frame(height: 8)
                    
                    // 3. Progress Bar & XP Text
                    VStack(alignment: .leading, spacing: 6) {
                        // Thanh trượt (Track + Fill)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(progressBg)
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(progressFill)
                                .frame(width: progressAnimation * 100, height: 6)
                        }
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                                progressAnimation = 0.65
                            }
                        }
                        
                        HStack(spacing: 0) {
                            Text("2,350 / 3,600 XP")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                            
                            Spacer()
                            
                            Text("Còn 1,250 XP để lên cấp tiếp theo")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                        }
                    }
                }
                Spacer()
            }
            .padding(28)
        }
        // 4. Card Container với Depth, Inner Shadow & Corner Radius
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.14, green: 0.14, blue: 0.14), Color(red: 0.06, green: 0.06, blue: 0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                // Inner Shadow (Tạo độ sâu)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 6)
                        .mask(RoundedRectangle(cornerRadius: 28))
                )
                // Border sáng tinh tế
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}