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
        Button(action: {}) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(red: 0.25, green: 0.25, blue: 0.25), Color(red: 0.1, green: 0.1, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 42, height: 42)
                    Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5).frame(width: 42, height: 42)
                    Image(systemName: item.iconName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                    Text(item.subtitle).font(.system(size: 11, weight: .regular, design: .rounded)).foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                }
                
                Spacer()
                Text(item.date).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
            }
            .padding(14)
            .background(Color(red: 0.08, green: 0.08, blue: 0.08))
            
            // === QUAN TRỌNG: Viền sáng đứt quãng (Glass Highlight) ===
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.5), location: 0.0),
                                .init(color: .white.opacity(0.1), location: 0.3),
                                .init(color: .clear, location: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 2).blur(radius: 4))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in isPressed = pressing }, perform: {})
    }
}