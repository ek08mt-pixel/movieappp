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
    
    // Tạo điểm sáng Offset ngẫu nhiên cho mỗi ô
    // Để "Mỗi ô viền khác nhau"
    private let startPoint: UnitPoint
    private let endPoint: UnitPoint
    
    init(item: AchievementItem) {
        self.item = item
        // Random vị trí sáng cho từng Card
        let seeds: [UnitPoint] = [.topLeading, .top, .topTrailing, .leading, .trailing, .bottomLeading, .bottom]
        self.startPoint = seeds.randomElement() ?? .topLeading
        self.endPoint = seeds.randomElement() ?? .bottomTrailing
    }
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(red: 0.25, green: 0.25, blue: 0.25), Color(red: 0.1, green: 0.1, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 42, height: 42)
                    Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5).frame(width: 42, height: 42)
                    Image(systemName: item.iconName).font(.system(size: 17, weight: .medium)).foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                    Text(item.subtitle).font(.system(size: 11, weight: .regular, design: .rounded)).foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.65))
                }
                
                Spacer()
                Text(item.date).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
            }
            .padding(14)
            .background(Color(red: 0.08, green: 0.08, blue: 0.08))
            
            // == VIỀN MỜ XUNG QUANH KHUNG, MỖI Ô KHÁC NHAU ==
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.6), location: 0.0),
                                .init(color: .white.opacity(0.0), location: 0.3),
                                .init(color: .white.opacity(0.4), location: 0.6),
                                .init(color: .white.opacity(0.0), location: 1.0)
                            ],
                            startPoint: startPoint,
                            endPoint: endPoint
                        ),
                        lineWidth: 0.8
                    )
            )
            // Lớp blur nhẹ tạo hiệu ứng sáng chạy
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 3)
                    .blur(radius: 2)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in isPressed = pressing }, perform: {})
    }
}