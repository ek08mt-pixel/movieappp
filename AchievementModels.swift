//
//  AchievementModels.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

// MARK: - Dữ liệu cho phần "Hành trình của bạn" (Timeline)
struct JourneyStage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let level: String
    let isUnlocked: Bool
    
    // Tính toán tên SF Symbol dựa trên title
    var iconName: String {
        switch title {
        case "Newbie": return "crown.fill"
        case "Enthusiast": return "bolt.fill"
        case "Fanatic": return "flame.fill"
        case "Pro Watcher": return "cat.fill" // Tạm thời dùng cat.fill
        case "Master": return "star.fill"
        case "Legend": return "medal.fill"
        default: return "questionmark"
        }
    }
}

// MARK: - Dữ liệu cho phần "Danh hiệu nổi bật" (List View)
struct AchievementItem: Identifiable {
    let id = UUID()
    let iconName: String // Tên SF Symbol
    let title: String
    let subtitle: String
    let date: String
}