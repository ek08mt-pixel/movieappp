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
    
    // State cho Category Tabs (Animation)
    @State private var selectedTab = "Tổng quan"
    private let tabs = ["Tổng quan", "Xem phim", "Thể loại", "Liên tục", "Hiếm"]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) { // Khoảng cách lớn giữa các Section (Premium feel)
                    
                    // 1. Custom Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color(red: 0.12, green: 0.12, blue: 0.12)))
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        
                        Spacer()
                        
                        Text("Danh hiệu")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // 2. Interactive Category Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tabs, id: \.self) { tab in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedTab = tab
                                    }
                                }) {
                                    Text(tab)
                                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                                        .foregroundColor(selectedTab == tab ? .white : Color(red: 0.55, green: 0.55, blue: 0.55))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedTab == tab ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 3. Hero Card
                    AchievementHeroCard()
                        .padding(.horizontal, 20)
                    
                    // 4. Timeline
                    AchievementTimelineRow(stages: viewModel.journeyStages)
                        .padding(.horizontal, 20)
                    
                    // 5. Achievement List Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("DANH HIỆU NỔI BẬT")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .tracking(1.5)
                                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                            
                            Spacer()
                            
                            Button(action: {
                                // Xử lý xem tất cả
                            }) {
                                HStack(spacing: 4) {
                                    Text("Xem tất cả")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        
                        // Render List Cards
                        VStack(spacing: 16) {
                            ForEach(viewModel.achievements) { item in
                                AchievementListItemView(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40) // Khoảng trống cho Custom TabBar
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AchievementView()
}