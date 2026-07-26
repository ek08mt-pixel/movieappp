//
//  AchievementListItemView.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

struct AchievementListItemView: View {
    let item: AchievementItem
    
    // Press Effect State
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback nhẹ (tùy chọn, nếu muốn)
            // UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            // Xử lý bấm vào Danh hiệu tại đây
            print("Tapped on: \(item.title)")
        }) {
            HStack(spacing: 20) {
                // Icon Container với Gradient/Depth
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.18, green: 0.18, blue: 0.18), Color(red: 0.08, green: 0.08, blue: 0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        .frame(width: 56, height: 56)
                    
                    // Icon (SF Symbol tạm thời)
                    Image(systemName: item.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(item.subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                }
                
                Spacer()
                
                // Date Text
                Text(item.date)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1)) // #1A1A1A
                    // Chiều sâu Inner Shadow
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 4)
                            .mask(RoundedRectangle(cornerRadius: 24))
                    )
                    // Border rất mờ
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            // Press Effect (Scale xuống 0.97 khi giữ)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain) // Tắt hiệu ứng mặc định của Button để dùng custom effect
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}