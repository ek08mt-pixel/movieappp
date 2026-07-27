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
// MARK: - Rank System
enum Rank: String, CaseIterable, Codable {
    case newbie = "Mèo Tập Xem"
    case explorer = "Mèo Khám Phá"
    case movieFan = "Mèo Cày Phim"
    case enthusiast = "Mèo Nghiện Phim"
    case proWatcher = "Mèo Pro"
    case master = "Mèo Đại Sư"
    case legend = "Mèo Huyền Thoại"
    case mythic = "Mèo Thần Thoại"
    
    var shortName: String {
        switch self {
        case .newbie: return "Gà Mờ"
        case .explorer: return "Tò Mò"
        case .movieFan: return "Mọt Phim"
        case .enthusiast: return "Chiến Thần"
        case .proWatcher: return "Dân Chơi"
        case .master: return "Ông Trùm"
        case .legend: return "Cực Phẩm"
        case .mythic: return "Bá Chủ"
        }
    }
    
    var level: Int {
        switch self {
        case .newbie: return 1
        case .explorer: return 5
        case .movieFan: return 10
        case .enthusiast: return 20
        case .proWatcher: return 35
        case .master: return 50
        case .legend: return 75
        case .mythic: return 100
        }
    }
    
    var xpRequired: Int {
        switch self {
        case .newbie: return 0
        case .explorer: return 150
        case .movieFan: return 500
        case .enthusiast: return 1200
        case .proWatcher: return 2500
        case .master: return 5000
        case .legend: return 10000
        case .mythic: return 20000
        }
    }
    
    var color: Color {
        switch self {
        case .newbie: return Color(white: 0.5)
        case .explorer: return Color(red: 0.8, green: 0.55, blue: 0.25)
        case .movieFan: return Color(red: 0.7, green: 0.7, blue: 0.75)
        case .enthusiast: return Color(red: 1.0, green: 0.85, blue: 0.1)
        case .proWatcher: return Color(red: 0.0, green: 0.75, blue: 0.95)
        case .master: return Color(red: 0.7, green: 0.2, blue: 0.9)
        case .legend: return Color(red: 1.0, green: 0.55, blue: 0.0)
        case .mythic: return Color(red: 1.0, green: 0.15, blue: 0.2)
        }
    }
    
    var glowColor: Color {
        switch self {
        case .newbie: return .clear
        case .explorer: return color.opacity(0.3)
        case .movieFan: return color.opacity(0.35)
        case .enthusiast: return color.opacity(0.4)
        case .proWatcher: return color.opacity(0.5)
        case .master: return color.opacity(0.55)
        case .legend: return color.opacity(0.6)
        case .mythic: return color.opacity(0.7)
        }
    }
    
    var tagline: String {
        switch self {
        case .newbie: return "Vừa bắt đầu cuộc chơi"
        case .explorer: return "Đang mò mẫm khám phá"
        case .movieFan: return "Cày như không có ngày mai"
        case .enthusiast: return "Nghiện tới mức không ngủ"
        case .proWatcher: return "Pro thực sự rồi đấy"
        case .master: return "Đẳng cấp đại sư"
        case .legend: return "Tên tuổi lưu danh sử sách"
        case .mythic: return "Cả vũ trụ biết tên bạn"
        }
    }
}

// MARK: - User Rank Data
struct UserRankData: Codable {
    var totalXP: Int
    var unlockedAchievements: Int
    var totalAchievements: Int
    
    var currentRank: Rank {
        let sorted = Rank.allCases.sorted { $0.xpRequired < $1.xpRequired }
        return sorted.last(where: { totalXP >= $0.xpRequired }) ?? .newbie
    }
    
    var nextRank: Rank? {
        let sorted = Rank.allCases.sorted { $0.xpRequired < $1.xpRequired }
        return sorted.first(where: { $0.xpRequired > totalXP })
    }
    
    var level: Int {
        let baseXP = currentRank.xpRequired
        let nextXP = nextRank?.xpRequired ?? (currentRank.xpRequired * 2)
        let range = max(nextXP - baseXP, 1)
        let progress = totalXP - baseXP
        let levelsInRank: Int = {
            switch currentRank {
            case .newbie: return 4
            case .explorer: return 5
            case .movieFan: return 10
            case .enthusiast: return 15
            case .proWatcher: return 15
            case .master: return 25
            case .legend: return 25
            case .mythic: return 100
            }
        }()
        return currentRank.level + Int((Double(progress) / Double(range)) * Double(levelsInRank))
    }
    
    var percentile: Int {
        switch currentRank {
        case .newbie: return 92
        case .explorer: return 72
        case .movieFan: return 50
        case .enthusiast: return 30
        case .proWatcher: return 15
        case .master: return 6
        case .legend: return 2
        case .mythic: return 1
        }
    }
}