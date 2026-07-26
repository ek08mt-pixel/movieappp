import SwiftUI

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
        case .newbie: return "NEWBIE"
        case .explorer: return "EXPLORER"
        case .movieFan: return "FAN"
        case .enthusiast: return "ENTHUSIAST"
        case .proWatcher: return "PRO"
        case .master: return "MASTER"
        case .legend: return "LEGEND"
        case .mythic: return "MYTHIC"
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

// MARK: - Achievement Category
enum AchievementCategory: String, CaseIterable, Codable {
    case all = "Tất cả"
    case watching = "Cày Phim"
    case genre = "Thể Loại"
    case time = "Thời Gian"
    case streak = "Xem Liên Tục"
    case rare = "Hiếm Có"
    case event = "Sự Kiện"
}

// MARK: - Achievement Tier
struct AchievementTier: Codable, Identifiable {
    var id: String { "\(achievementId)_\(tier)" }
    let achievementId: String
    let tier: Int
    let name: String
    let requirement: Int
    let description: String
    let vibe: String
    
    func isUnlocked(current: Int) -> Bool { current >= requirement }
    func progress(current: Int) -> Double { min(Double(current) / Double(requirement), 1.0) }
}

// MARK: - Achievement Definition
struct AchievementDefinition: Codable, Identifiable {
    let id: String
    let category: AchievementCategory
    let title: String
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

// MARK: - Achievement Data (Static Definitions - no emoji)
struct AchievementData {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: "movie_buff", category: .watching, title: "Cày Phim", tiers: [
            AchievementTier(achievementId: "movie_buff", tier: 1, name: "Mới tập cày", requirement: 10, description: "Xem 10 phim", vibe: "Chân ái vừa bắt đầu"),
            AchievementTier(achievementId: "movie_buff", tier: 2, name: "Cày khá", requirement: 50, description: "Xem 50 phim", vibe: "Đã biết mùi phim"),
            AchievementTier(achievementId: "movie_buff", tier: 3, name: "Cày xuyên đêm", requirement: 100, description: "Xem 100 phim", vibe: "Ngủ làm gì khi còn phim"),
            AchievementTier(achievementId: "movie_buff", tier: 4, name: "Cày bất chấp", requirement: 250, description: "Xem 250 phim", vibe: "Mưa bão cũng không ngăn được"),
            AchievementTier(achievementId: "movie_buff", tier: 5, name: "Cày thủng nóc", requirement: 500, description: "Xem 500 phim", vibe: "Server phim sợ bạn rồi"),
            AchievementTier(achievementId: "movie_buff", tier: 6, name: "Cày xuyên không gian", requirement: 1000, description: "Xem 1.000 phim", vibe: "Không gian 4 chiều cũng cày"),
            AchievementTier(achievementId: "movie_buff", tier: 7, name: "Cày Vip Pro Max", requirement: 2500, description: "Xem 2.500 phim", vibe: "Bạn chính là phim")
        ]),
        AchievementDefinition(id: "marathon", category: .streak, title: "Marathon", tiers: [
            AchievementTier(achievementId: "marathon", tier: 1, name: "Chạy đà", requirement: 2, description: "2 phim liên tục", vibe: "Khởi động nhẹ"),
            AchievementTier(achievementId: "marathon", tier: 2, name: "Chạy nước rút", requirement: 5, description: "5 phim liên tục", vibe: "Pin còn 1% vẫn chiến"),
            AchievementTier(achievementId: "marathon", tier: 3, name: "Chạy marathon", requirement: 10, description: "10 phim liên tục", vibe: "Đã quên mùi ánh sáng mặt trời"),
            AchievementTier(achievementId: "marathon", tier: 4, name: "Ultra Marathon", requirement: 20, description: "20 phim liên tục", vibe: "Bạn là cỗ máy không cần ngủ"),
            AchievementTier(achievementId: "marathon", tier: 5, name: "Marathon Huyền Thoại", requirement: 50, description: "50 phim liên tục", vibe: "Cơ thể bạn giờ là Netflix")
        ]),
        AchievementDefinition(id: "night_owl", category: .time, title: "Cú Đêm", tiers: [
            AchievementTier(achievementId: "night_owl", tier: 1, name: "Cú non", requirement: 5, description: "Xem sau 22h 5 lần", vibe: "Mới tập thức đêm"),
            AchievementTier(achievementId: "night_owl", tier: 2, name: "Cú trưởng thành", requirement: 20, description: "Xem sau 22h 20 lần", vibe: "Đêm là nhà"),
            AchievementTier(achievementId: "night_owl", tier: 3, name: "Cú chiến", requirement: 50, description: "Xem sau 22h 50 lần", vibe: "Quên mất mặt trời mọc hướng nào"),
            AchievementTier(achievementId: "night_owl", tier: 4, name: "Cú tinh anh", requirement: 100, description: "Xem sau 22h 100 lần", vibe: "Cú đêm đỉnh cao"),
            AchievementTier(achievementId: "night_owl", tier: 5, name: "Cú Vip Pro", requirement: 300, description: "Xem sau 22h 300 lần", vibe: "Bạn và bóng tối là một")
        ]),
        AchievementDefinition(id: "horror_expert", category: .genre, title: "Thợ Săn Ma", tiers: [
            AchievementTier(achievementId: "horror_expert", tier: 1, name: "Sợ nhưng vẫn xem", requirement: 10, description: "10 phim kinh dị", vibe: "Núp chăn nhưng không tắt"),
            AchievementTier(achievementId: "horror_expert", tier: 2, name: "Gan thép", requirement: 30, description: "30 phim kinh dị", vibe: "Ma còn sợ bạn"),
            AchievementTier(achievementId: "horror_expert", tier: 3, name: "Thợ săn ma", requirement: 50, description: "50 phim kinh dị", vibe: "Không con ma nào dám hù"),
            AchievementTier(achievementId: "horror_expert", tier: 4, name: "Ma Vương", requirement: 100, description: "100 phim kinh dị", vibe: "Bạn là trùm cuối")
        ]),
        AchievementDefinition(id: "comedy_king", category: .genre, title: "Vua Hài", tiers: [
            AchievementTier(achievementId: "comedy_king", tier: 1, name: "Cười mỉm", requirement: 10, description: "10 phim hài", vibe: "Mới cười nhẹ"),
            AchievementTier(achievementId: "comedy_king", tier: 2, name: "Cười sảng khoái", requirement: 30, description: "30 phim hài", vibe: "Cơ bụng đã săn chắc"),
            AchievementTier(achievementId: "comedy_king", tier: 3, name: "Cười ra nước mắt", requirement: 50, description: "50 phim hài", vibe: "Hàng xóm tưởng bạn điên"),
            AchievementTier(achievementId: "comedy_king", tier: 4, name: "Vua Hài", requirement: 100, description: "100 phim hài", vibe: "Bạn chính là joke")
        ]),
        AchievementDefinition(id: "drama_master", category: .genre, title: "Thánh Drama", tiers: [
            AchievementTier(achievementId: "drama_master", tier: 1, name: "Xem drama sơ cấp", requirement: 10, description: "10 phim Drama", vibe: "Mới rơi vài giọt"),
            AchievementTier(achievementId: "drama_master", tier: 2, name: "Drama trung cấp", requirement: 30, description: "30 phim Drama", vibe: "Khăn giấy đã hết hộp thứ 3"),
            AchievementTier(achievementId: "drama_master", tier: 3, name: "Thánh Drama", requirement: 50, description: "50 phim Drama", vibe: "Mắt lúc nào cũng ướt"),
            AchievementTier(achievementId: "drama_master", tier: 4, name: "Drama Vip Pro", requirement: 100, description: "100 phim Drama", vibe: "Bạn là biển nước mắt")
        ]),
        AchievementDefinition(id: "scifi_explorer", category: .genre, title: "Người Du Hành", tiers: [
            AchievementTier(achievementId: "scifi_explorer", tier: 1, name: "Du hành tập sự", requirement: 10, description: "10 phim Sci-Fi", vibe: "Vừa rời bệ phóng"),
            AchievementTier(achievementId: "scifi_explorer", tier: 2, name: "Du hành liên hành tinh", requirement: 30, description: "30 phim Sci-Fi", vibe: "Bay qua sao Hỏa như đi chợ"),
            AchievementTier(achievementId: "scifi_explorer", tier: 3, name: "Du hành liên thiên hà", requirement: 50, description: "50 phim Sci-Fi", vibe: "Black hole cũng né bạn"),
            AchievementTier(achievementId: "scifi_explorer", tier: 4, name: "Chúa tể vũ trụ", requirement: 100, description: "100 phim Sci-Fi", vibe: "Bạn sở hữu dải ngân hà")
        ]),
        AchievementDefinition(id: "romance_lover", category: .genre, title: "Tình Yêu Vô Cực", tiers: [
            AchievementTier(achievementId: "romance_lover", tier: 1, name: "Tim rung nhẹ", requirement: 10, description: "10 phim tình cảm", vibe: "Crush vẫn chưa rep"),
            AchievementTier(achievementId: "romance_lover", tier: 2, name: "Yêu say đắm", requirement: 30, description: "30 phim tình cảm", vibe: "Đã có người yêu trong mơ"),
            AchievementTier(achievementId: "romance_lover", tier: 3, name: "Tình yêu bất diệt", requirement: 50, description: "50 phim tình cảm", vibe: "Yêu nhiều hơn cả Romeo"),
            AchievementTier(achievementId: "romance_lover", tier: 4, name: "Thánh Tình Yêu", requirement: 100, description: "100 phim tình cảm", vibe: "Cả thế giới yêu bạn")
        ]),
        AchievementDefinition(id: "watch_time", category: .time, title: "Thời Gian Cày", tiers: [
            AchievementTier(achievementId: "watch_time", tier: 1, name: "10 giờ", requirement: 600, description: "Xem 10 giờ", vibe: "Một ngày làm việc"),
            AchievementTier(achievementId: "watch_time", tier: 2, name: "50 giờ", requirement: 3000, description: "Xem 50 giờ", vibe: "Hơn 2 ngày không ngủ"),
            AchievementTier(achievementId: "watch_time", tier: 3, name: "100 giờ", requirement: 6000, description: "Xem 100 giờ", vibe: "Một tuần biến mất"),
            AchievementTier(achievementId: "watch_time", tier: 4, name: "300 giờ", requirement: 18000, description: "Xem 300 giờ", vibe: "Nửa tháng trong bóng tối"),
            AchievementTier(achievementId: "watch_time", tier: 5, name: "1000 giờ", requirement: 60000, description: "Xem 1000 giờ", vibe: "Bạn đã dành cả thanh xuân")
        ]),
        AchievementDefinition(id: "christmas", category: .event, title: "Giáng Sinh", tiers: [
            AchievementTier(achievementId: "christmas", tier: 1, name: "Ông già Noel", requirement: 1, description: "Xem phim vào Giáng sinh", vibe: "Quà là phim")
        ]),
        AchievementDefinition(id: "halloween", category: .event, title: "Halloween", tiers: [
            AchievementTier(achievementId: "halloween", tier: 1, name: "Ma đói", requirement: 1, description: "Xem phim vào Halloween", vibe: "Trick or treat là xem phim")
        ]),
        AchievementDefinition(id: "valentine", category: .event, title: "Valentine", tiers: [
            AchievementTier(achievementId: "valentine", tier: 1, name: "Trái tim cô đơn", requirement: 1, description: "Xem phim vào Valentine", vibe: "Phim là người yêu")
        ]),
        AchievementDefinition(id: "new_year", category: .event, title: "Năm Mới", tiers: [
            AchievementTier(achievementId: "new_year", tier: 1, name: "Pháo hoa đầu năm", requirement: 1, description: "Xem phim vào năm mới", vibe: "New year, new phim")
        ])
    ]
}