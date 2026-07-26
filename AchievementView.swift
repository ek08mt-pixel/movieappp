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
    
    @State private var selectedTab = "Tổng quan"
    private let tabs = ["Tổng quan", "Xem phim", "Thể loại", "Liên tục", "Hiếm"]
    
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.04).ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // 1. Custom Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(red: 0.1, green: 0.1, blue: 0.1)))
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        
                        Spacer()
                        
                        Text("Danh hiệu")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 20)
                    
                    // 2. Interactive Category Tabs (Tương thích iOS 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tabs, id: \.self) { tab in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedTab = tab
                                    }
                                }) {
                                    Text(tab)
                                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular, design: .rounded))
                                        .foregroundColor(selectedTab == tab ? .white : Color(red: 0.55, green: 0.55, blue: 0.55))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(selectedTab == tab ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20) // Giữ padding 2 bên để không bị dính sát lề màn hình
                    }
                    
                    // 3. Hero Card
                    AchievementHeroCard()
                        .padding(.horizontal, 20)
                    
                    // 4. Timeline
                    AchievementTimelineRow(stages: viewModel.journeyStages)
                        .padding(.horizontal, 16)
                    
                    // 5. Achievement List Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("DANH HIỆU NỔI BẬT")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                            
                            Spacer()
                            
                            Button(action: {}) {
                                HStack(spacing: 4) {
                                    Text("Xem tất cả")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        
                        // Render List Cards
                        VStack(spacing: 12) {
                            ForEach(viewModel.achievements) { item in
                                AchievementListItemView(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AchievementView()
}