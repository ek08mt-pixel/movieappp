//
//  AchievementListItemView.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

struct AchievementListItemView: View {
    let item: AchievementItem
    private let cardBgColor = Color(red: 0.1, green: 0.1, blue: 0.1) // Màu nền item tối hơn một chút so với card chính
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circular Background
            ZStack {
                Circle()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .frame(width: 48, height: 48)
                
                // Icon Shape (Đã được scale và căn giữa)
                AnyView(item.iconShape)
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
            }
            
            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(item.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Date Text (Ngày nhận danh hiệu)
            Text(item.date)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
                .padding(.leading, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBgColor)
        )
    }
}

#Preview {
    ZStack {
        Color.black
        AchievementListItemView(
            item: AchievementItem(
                iconShape: LightningShape(),
                title: "Cú Đêm Chính Hiệu",
                subtitle: "Xem phim từ 23:00 đến 3:00",
                date: "12.05.2024"
            )
        )
        .padding(.horizontal, 16)
    }
}