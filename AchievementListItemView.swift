//
//  AchievementListItemView.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

struct AchievementListItemView: View {
    let item: AchievementItem
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback nhẹ (tùy chọn)
        }) {
            HStack(spacing: 16) {
                // Icon Container (Thu nhỏ lại cho cân đối)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.18, green: 0.18, blue: 0.18), Color(red: 0.08, green: 0.08, blue: 0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        .frame(width: 44, height: 44)
                    
                    // Icon (SF Symbol)
                    Image(systemName: item.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(item.subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                }
                
                Spacer()
                
                // Date Text
                Text(item.date)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}