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
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(red: 0.1, green: 0.1, blue: 0.1)))
                                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        Spacer()
                        Text("Danh hiệu")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 10) {
        ForEach(tabs, id: \.self) { tab in
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedTab = tab
                }
            }) {
                Text(tab)
                    .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                    .foregroundColor(selectedTab == tab ? .white : .gray)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab ? Color.white.opacity(0.12) : Color.white.opacity(0.03))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                selectedTab == tab ?
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                                lineWidth: 0.8
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }
    .padding(.horizontal, 20)
}
                    
                    // Hero
                    AchievementHeroCard().padding(.horizontal, 20)
                    
                    // Timeline
                    AchievementTimelineRow(stages: viewModel.journeyStages)
                        .padding(.horizontal, 16)
                    
                    // List Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("DANH HIỆU NỔI BẬT")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                            Spacer()
                            Button(action: {}) {
                                HStack(spacing: 3) {
                                    Text("Xem tất cả").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                    Image(systemName: "chevron.right").font(.system(size: 9)).foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        
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