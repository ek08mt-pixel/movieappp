import SwiftUI

// MARK: - Rank System
enum Rank: String, CaseIterable, Codable {
    case newbie = "Newbie"
    case explorer = "Explorer"
    case movieFan = "Movie Fan"
    case enthusiast = "Enthusiast"
    case proWatcher = "Pro Watcher"
    case master = "Master"
    case legend = "Legend"
    case mythic = "Mythic"
    
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
        case .explorer: return 100
        case .movieFan: return 350
        case .enthusiast: return 800
        case .proWatcher: return 1500
        case .master: return 3000
        case .legend: return 6000
        case .mythic: return 12000
        }
    }
    
    var icon: String {
        switch self {
        case .newbie: return "🥚"
        case .explorer: return "🥉"
        case .movieFan: return "🥈"
        case .enthusiast: return "🥇"
        case .proWatcher: return "💎"
        case .master: return "👑"
        case .legend: return "🌟"
        case .mythic: return "🔥"
        }
    }
    
    var color: Color {
        switch self {
        case .newbie: return .gray
        case .explorer: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .movieFan: return Color(white: 0.75)
        case .enthusiast: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .proWatcher: return Color(red: 0.0, green: 0.8, blue: 1.0)
        case .master: return Color(red: 0.8, green: 0.2, blue: 0.8)
        case .legend: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .mythic: return Color(red: 1.0, green: 0.2, blue: 0.2)
        }
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, CaseIterable, Codable {
    case all = "Tất cả"
    case watching = "Xem phim"
    case genre = "Thể loại"
    case time = "Thời gian"
    case streak = "Liên tục"
    case rare = "Hiếm"
    case event = "Sự kiện"
}

// MARK: - Achievement Tier
struct AchievementTier: Codable, Identifiable {
    var id: String { "\(achievementId)_\(tier)" }
    let achievementId: String
    let tier: Int
    let name: String
    let icon: String
    let requirement: Int
    let description: String
    
    func isUnlocked(current: Int) -> Bool { current >= requirement }
    func progress(current: Int) -> Double { min(Double(current) / Double(requirement), 1.0) }
}

// MARK: - Achievement Definition
struct AchievementDefinition: Codable, Identifiable {
    let id: String
    let category: AchievementCategory
    let title: String
    let icon: String
    let tiers: [AchievementTier]
    
    func currentTier(progress: Int) -> AchievementTier? {
        tiers.last(where: { $0.requirement <= progress })
    }
    
    func nextTier(progress: Int) -> AchievementTier? {
        tiers.first(where: { $0.requirement > progress })
    }
}

// MARK: - User Progress
struct AchievementProgress: Codable, Identifiable {
    var id: String { achievementId }
    let achievementId: String
    var currentValue: Int
    var unlockedTiers: [Int]
    var completedAt: Date?
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
        let range = nextXP - baseXP
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
        case .newbie: return 95
        case .explorer: return 75
        case .movieFan: return 55
        case .enthusiast: return 35
        case .proWatcher: return 18
        case .master: return 8
        case .legend: return 3
        case .mythic: return 1
        }
    }
}

// MARK: - Mock Data
struct AchievementMockData {
    static let achievements: [AchievementDefinition] = [
        // Xem phim
        AchievementDefinition(id: "movie_buff", category: .watching, title: "Movie Buff", icon: "🎬", tiers: [
            AchievementTier(achievementId: "movie_buff", tier: 1, name: "Movie Buff I", icon: "🎬", requirement: 10, description: "Xem 10 phim"),
            AchievementTier(achievementId: "movie_buff", tier: 2, name: "Movie Buff II", icon: "🍿", requirement: 50, description: "Xem 50 phim"),
            AchievementTier(achievementId: "movie_buff", tier: 3, name: "Movie Buff III", icon: "🎥", requirement: 100, description: "Xem 100 phim"),
            AchievementTier(achievementId: "movie_buff", tier: 4, name: "Movie Buff IV", icon: "📽", requirement: 250, description: "Xem 250 phim"),
            AchievementTier(achievementId: "movie_buff", tier: 5, name: "Movie Buff V", icon: "🎞", requirement: 500, description: "Xem 500 phim"),
            AchievementTier(achievementId: "movie_buff", tier: 6, name: "Movie Buff VI", icon: "🍿", requirement: 1000, description: "Xem 1.000 phim"),
            AchievementTier(achievementId: "movie_buff", tier: 7, name: "Movie Buff VII", icon: "👑", requirement: 2500, description: "Xem 2.500 phim")
        ]),
        AchievementDefinition(id: "first_movie", category: .watching, title: "First Movie", icon: "▶️", tiers: [
            AchievementTier(achievementId: "first_movie", tier: 1, name: "First Movie", icon: "▶️", requirement: 1, description: "Xem phim đầu tiên")
        ]),
        
        // Xem liên tục
        AchievementDefinition(id: "marathon", category: .streak, title: "Marathon", icon: "⚡", tiers: [
            AchievementTier(achievementId: "marathon", tier: 1, name: "Marathon I", icon: "⚡", requirement: 2, description: "2 phim liên tục"),
            AchievementTier(achievementId: "marathon", tier: 2, name: "Marathon II", icon: "⚡", requirement: 5, description: "5 phim liên tục"),
            AchievementTier(achievementId: "marathon", tier: 3, name: "Marathon III", icon: "⚡", requirement: 10, description: "10 phim liên tục"),
            AchievementTier(achievementId: "marathon", tier: 4, name: "Marathon IV", icon: "⚡", requirement: 20, description: "20 phim liên tục"),
            AchievementTier(achievementId: "marathon", tier: 5, name: "Marathon V", icon: "⚡", requirement: 50, description: "50 phim liên tục")
        ]),
        AchievementDefinition(id: "binge_master", category: .streak, title: "Binge Master", icon: "🍕", tiers: [
            AchievementTier(achievementId: "binge_master", tier: 1, name: "Binge Master I", icon: "🍕", requirement: 3, description: "Xem liên tục 3 phim"),
            AchievementTier(achievementId: "binge_master", tier: 2, name: "Binge Master II", icon: "🍕", requirement: 5, description: "Xem liên tục 5 phim"),
            AchievementTier(achievementId: "binge_master", tier: 3, name: "Binge Master III", icon: "🍕", requirement: 10, description: "Xem liên tục 10 phim")
        ]),
        
        // Theo giờ
        AchievementDefinition(id: "night_owl", category: .time, title: "Night Owl", icon: "🌙", tiers: [
            AchievementTier(achievementId: "night_owl", tier: 1, name: "Night Owl I", icon: "🌙", requirement: 5, description: "Xem sau 22h 5 lần"),
            AchievementTier(achievementId: "night_owl", tier: 2, name: "Night Owl II", icon: "🌙", requirement: 20, description: "Xem sau 22h 20 lần"),
            AchievementTier(achievementId: "night_owl", tier: 3, name: "Night Owl III", icon: "🌙", requirement: 50, description: "Xem sau 22h 50 lần"),
            AchievementTier(achievementId: "night_owl", tier: 4, name: "Night Owl IV", icon: "🌙", requirement: 100, description: "Xem sau 22h 100 lần"),
            AchievementTier(achievementId: "night_owl", tier: 5, name: "Night Owl V", icon: "🌙", requirement: 300, description: "Xem sau 22h 300 lần")
        ]),
        AchievementDefinition(id: "early_bird", category: .time, title: "Early Bird", icon: "🌅", tiers: [
            AchievementTier(achievementId: "early_bird", tier: 1, name: "Early Bird I", icon: "🌅", requirement: 5, description: "Xem trước 6h 5 lần"),
            AchievementTier(achievementId: "early_bird", tier: 2, name: "Early Bird II", icon: "🌅", requirement: 20, description: "Xem trước 6h 20 lần"),
            AchievementTier(achievementId: "early_bird", tier: 3, name: "Early Bird III", icon: "🌅", requirement: 50, description: "Xem trước 6h 50 lần")
        ]),
        
        // Thể loại
        AchievementDefinition(id: "horror_expert", category: .genre, title: "Horror Expert", icon: "👻", tiers: [
            AchievementTier(achievementId: "horror_expert", tier: 1, name: "Horror Expert I", icon: "👻", requirement: 10, description: "10 phim kinh dị"),
            AchievementTier(achievementId: "horror_expert", tier: 2, name: "Horror Expert II", icon: "👻", requirement: 30, description: "30 phim kinh dị"),
            AchievementTier(achievementId: "horror_expert", tier: 3, name: "Horror Expert III", icon: "👻", requirement: 50, description: "50 phim kinh dị"),
            AchievementTier(achievementId: "horror_expert", tier: 4, name: "Horror Expert IV", icon: "👻", requirement: 100, description: "100 phim kinh dị")
        ]),
        AchievementDefinition(id: "comedy_king", category: .genre, title: "Comedy King", icon: "😂", tiers: [
            AchievementTier(achievementId: "comedy_king", tier: 1, name: "Comedy King I", icon: "😂", requirement: 10, description: "10 phim hài"),
            AchievementTier(achievementId: "comedy_king", tier: 2, name: "Comedy King II", icon: "😂", requirement: 30, description: "30 phim hài"),
            AchievementTier(achievementId: "comedy_king", tier: 3, name: "Comedy King III", icon: "😂", requirement: 50, description: "50 phim hài"),
            AchievementTier(achievementId: "comedy_king", tier: 4, name: "Comedy King IV", icon: "😂", requirement: 100, description: "100 phim hài")
        ]),
        AchievementDefinition(id: "drama_master", category: .genre, title: "Drama Master", icon: "😭", tiers: [
            AchievementTier(achievementId: "drama_master", tier: 1, name: "Drama Master I", icon: "😭", requirement: 10, description: "10 phim Drama"),
            AchievementTier(achievementId: "drama_master", tier: 2, name: "Drama Master II", icon: "😭", requirement: 30, description: "30 phim Drama"),
            AchievementTier(achievementId: "drama_master", tier: 3, name: "Drama Master III", icon: "😭", requirement: 50, description: "50 phim Drama"),
            AchievementTier(achievementId: "drama_master", tier: 4, name: "Drama Master IV", icon: "😭", requirement: 100, description: "100 phim Drama")
        ]),
        AchievementDefinition(id: "scifi_explorer", category: .genre, title: "Sci-Fi Explorer", icon: "🚀", tiers: [
            AchievementTier(achievementId: "scifi_explorer", tier: 1, name: "Sci-Fi Explorer I", icon: "🚀", requirement: 10, description: "10 phim Sci-Fi"),
            AchievementTier(achievementId: "scifi_explorer", tier: 2, name: "Sci-Fi Explorer II", icon: "🚀", requirement: 30, description: "30 phim Sci-Fi"),
            AchievementTier(achievementId: "scifi_explorer", tier: 3, name: "Sci-Fi Explorer III", icon: "🚀", requirement: 50, description: "50 phim Sci-Fi"),
            AchievementTier(achievementId: "scifi_explorer", tier: 4, name: "Sci-Fi Explorer IV", icon: "🚀", requirement: 100, description: "100 phim Sci-Fi")
        ]),
        AchievementDefinition(id: "romance_lover", category: .genre, title: "Romance Lover", icon: "❤️", tiers: [
            AchievementTier(achievementId: "romance_lover", tier: 1, name: "Romance Lover I", icon: "❤️", requirement: 10, description: "10 phim tình cảm"),
            AchievementTier(achievementId: "romance_lover", tier: 2, name: "Romance Lover II", icon: "❤️", requirement: 30, description: "30 phim tình cảm"),
            AchievementTier(achievementId: "romance_lover", tier: 3, name: "Romance Lover III", icon: "❤️", requirement: 50, description: "50 phim tình cảm"),
            AchievementTier(achievementId: "romance_lover", tier: 4, name: "Romance Lover IV", icon: "❤️", requirement: 100, description: "100 phim tình cảm")
        ]),
        
        // Theo thời lượng
        AchievementDefinition(id: "watch_time", category: .time, title: "Watch Time", icon: "⏱", tiers: [
            AchievementTier(achievementId: "watch_time", tier: 1, name: "10 giờ", icon: "⏱", requirement: 600, description: "Xem 10 giờ"),
            AchievementTier(achievementId: "watch_time", tier: 2, name: "50 giờ", icon: "⏱", requirement: 3000, description: "Xem 50 giờ"),
            AchievementTier(achievementId: "watch_time", tier: 3, name: "100 giờ", icon: "⏱", requirement: 6000, description: "Xem 100 giờ"),
            AchievementTier(achievementId: "watch_time", tier: 4, name: "300 giờ", icon: "⏱", requirement: 18000, description: "Xem 300 giờ"),
            AchievementTier(achievementId: "watch_time", tier: 5, name: "1000 giờ", icon: "⏱", requirement: 60000, description: "Xem 1000 giờ")
        ]),
        
        // Hiếm
        AchievementDefinition(id: "christmas", category: .event, title: "Christmas Watcher", icon: "🎁", tiers: [
            AchievementTier(achievementId: "christmas", tier: 1, name: "Christmas Watcher", icon: "🎁", requirement: 1, description: "Xem phim vào Giáng sinh")
        ]),
        AchievementDefinition(id: "halloween", category: .event, title: "Halloween", icon: "🎃", tiers: [
            AchievementTier(achievementId: "halloween", tier: 1, name: "Halloween Watcher", icon: "🎃", requirement: 1, description: "Xem phim vào Halloween")
        ]),
        AchievementDefinition(id: "valentine", category: .event, title: "Valentine", icon: "💝", tiers: [
            AchievementTier(achievementId: "valentine", tier: 1, name: "Valentine Watcher", icon: "💝", requirement: 1, description: "Xem phim vào Valentine")
        ]),
        AchievementDefinition(id: "new_year", category: .event, title: "New Year", icon: "🎆", tiers: [
            AchievementTier(achievementId: "new_year", tier: 1, name: "New Year Watcher", icon: "🎆", requirement: 1, description: "Xem phim vào năm mới")
        ])
    ]
    
    static var userRankData: UserRankData {
        UserRankData(totalXP: 2350, unlockedAchievements: 12, totalAchievements: achievements.flatMap { $0.tiers }.count)
    }
    
    static var userProgress: [AchievementProgress] {
        [
            AchievementProgress(achievementId: "movie_buff", currentValue: 187, unlockedTiers: [1, 2, 3]),
            AchievementProgress(achievementId: "first_movie", currentValue: 1, unlockedTiers: [1]),
            AchievementProgress(achievementId: "marathon", currentValue: 8, unlockedTiers: [1, 2]),
            AchievementProgress(achievementId: "binge_master", currentValue: 4, unlockedTiers: [1]),
            AchievementProgress(achievementId: "night_owl", currentValue: 35, unlockedTiers: [1, 2]),
            AchievementProgress(achievementId: "early_bird", currentValue: 3, unlockedTiers: []),
            AchievementProgress(achievementId: "horror_expert", currentValue: 28, unlockedTiers: [1]),
            AchievementProgress(achievementId: "comedy_king", currentValue: 15, unlockedTiers: [1]),
            AchievementProgress(achievementId: "drama_master", currentValue: 28, unlockedTiers: [1]),
            AchievementProgress(achievementId: "scifi_explorer", currentValue: 42, unlockedTiers: [1, 2]),
            AchievementProgress(achievementId: "romance_lover", currentValue: 8, unlockedTiers: []),
            AchievementProgress(achievementId: "watch_time", currentValue: 3200, unlockedTiers: [1, 2]),
            AchievementProgress(achievementId: "christmas", currentValue: 1, unlockedTiers: [1]),
            AchievementProgress(achievementId: "new_year", currentValue: 1, unlockedTiers: [1])
        ]
    }
}