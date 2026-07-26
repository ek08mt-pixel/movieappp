//
//  AchievementView.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

struct AchievementView: View {
    @StateObject private var viewModel = AchievementManager()
    @Environment(\.dismiss) private var dismiss
    
    // Màu nền chung của app
    private let bgColor = Color.black
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // 1. Custom Header (Thay thế NavigationTitle mặc định để giống thiết kế)
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(red: 0.12, green: 0.12, blue: 0.12)))
                        }
                        
                        Spacer()
                        
                        Text("Danh hiệu")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Spacer đối xứng bên phải để giữ tiêu đề cân đối
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // 2. Tab Filter (Tổng quan, Xem phim, v.v.)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Text("Tổng quan")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(red: 0.15, green: 0.15, blue: 0.15)))
                            
                            Text("Xem phim")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textTertiary)
                            
                            Text("Thể loại")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textTertiary)
                            
                            Text("Liên tục")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textTertiary)
                            
                            Text("Hiếm")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textTertiary)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // 3. Hero Card (Pro Watcher)
                    AchievementHeroCard()
                        .padding(.horizontal, 16)
                    
                    // 4. Timeline (Hành trình của bạn)
                    AchievementTimelineRow(stages: viewModel.journeyStages)
                        .padding(.horizontal, 16)
                    
                    // 5. Danh sách nổi bật (Achievement List)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("DANH HIỆU NỔI BẬT")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(1.5)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("Xem tất cả")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        // Lặp qua danh sách achievements
                        ForEach(viewModel.achievements) { item in
                            AchievementListItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40) // Khoảng trống dưới cùng để tránh che bởi Tab Bar
                }
            }
        }
        .navigationBarHidden(true) // Ẩn thanh navigation mặc định vì chúng ta đã custom header thủ công
    }
}

#Preview {
    NavigationStack {
        AchievementView()
    }
}