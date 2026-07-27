import SwiftUI

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    // Dữ liệu Hành trình (tính từ XP thật)
    @Published var journeyStages: [JourneyStage] = []
    
    // Dữ liệu Danh hiệu nổi bật (tính từ lịch sử thật)
    @Published var achievements: [AchievementItem] = []
    
    // Dữ liệu Rank
    @Published var userRankData = UserRankData(totalXP: 0, unlockedAchievements: 0, totalAchievements: 0)
    @Published var progressList: [AchievementProgress] = []
    
    private let allDefinitions = AchievementData.all
    
    init() {
        loadFromUserDefaults()
        buildJourneyStages()
    }
    
    // MARK: - Refresh từ AppState
    func refresh(from appState: AppState) {
        let history = appState.watchHistory
        let progress = appState.watchProgressList
        
        // Tính XP
        var xp = 0
        xp += history.count * 10
        xp += appState.favorites.count * 5
        xp += appState.watchedMovies.count * 5
        xp += Int(progress.reduce(0) { $0 + $1.currentTime }) / 60
        
        // Tính achievement progress
        var newProgressList: [AchievementProgress] = []
        for ach in allDefinitions {
            let value = calculateValue(for: ach.id, history: history, progressList: progress)
            let unlockedTiers = ach.tiers.filter { $0.requirement <= value }.map { $0.tier }
            let p = AchievementProgress(
                achievementId: ach.id,
                currentValue: value,
                unlockedTiers: unlockedTiers,
                completedAt: unlockedTiers.count == ach.tiers.count ? Date() : nil
            )
            newProgressList.append(p)
        }
        
        let unlockedCount = newProgressList.reduce(0) { $0 + $1.unlockedTiers.count }
        let totalCount = allDefinitions.reduce(0) { $0 + $1.tiers.count }
        
        self.progressList = newProgressList
        self.userRankData = UserRankData(
            totalXP: xp,
            unlockedAchievements: unlockedCount,
            totalAchievements: totalCount
        )
        
        // Build lại journey stages theo XP thật
        buildJourneyStages()
        
        // Build danh sách danh hiệu nổi bật
        buildFeaturedAchievements(history: history, progressList: progress)
        
        saveToUserDefaults()
    }
    
    func progress(for achievementId: String) -> AchievementProgress? {
        progressList.first(where: { $0.achievementId == achievementId })
    }
    
    // MARK: - Build Journey Stages
    private func buildJourneyStages() {
        let currentRank = userRankData.currentRank
        var stages: [JourneyStage] = []
        for rank in Rank.allCases {
            stages.append(JourneyStage(
                title: rank.rawValue,
                level: "Lv.\(rank.level)",
                isUnlocked: rank.xpRequired <= userRankData.totalXP
            ))
        }
        self.journeyStages = stages
    }
    
    // MARK: - Build Featured Achievements
    private func buildFeaturedAchievements(history: [Movie], progressList: [WatchProgress]) {
        var items: [AchievementItem] = []
        
        // Night Owl
        let nightCount = progressList.filter {
            let hour = Calendar.current.component(.hour, from: $0.lastWatched)
            return hour >= 22 || hour < 6
        }.count
        if nightCount > 0 {
            items.append(AchievementItem(
                iconName: "moon.stars.fill",
                title: "Cú Đêm Chính Hiệu",
                subtitle: "Xem phim từ 23:00 đến 3:00",
                date: "\(nightCount) lần"
            ))
        }
        
        // Streak (Marathon)
        let streak = calculateStreak(history: history, progressList: progressList)
        if streak >= 2 {
            items.append(AchievementItem(
                iconName: "flame.fill",
                title: "Binge Master",
                subtitle: "Xem liên tục \(streak) tập phim",
                date: "Đang hoạt động"
            ))
        }
        
        // Drama count
        let dramaCount = countGenre(history: history, genreId: 18)
        if dramaCount > 0 {
            items.append(AchievementItem(
                iconName: "theatermasks.fill",
                title: "Drama Queen",
                subtitle: "Xem \(dramaCount) phim thể loại Drama",
                date: "Tổng cộng"
            ))
        }
        
        // Comedy count
        let comedyCount = countGenre(history: history, genreId: 35)
        if comedyCount > 0 && items.count < 5 {
            items.append(AchievementItem(
                iconName: "face.smiling.fill",
                title: "Vua Hài",
                subtitle: "Xem \(comedyCount) phim hài",
                date: "Tổng cộng"
            ))
        }
        
        // Horror count
        let horrorCount = countGenre(history: history, genreId: 27)
        if horrorCount > 0 && items.count < 5 {
            items.append(AchievementItem(
                iconName: "ghost.fill",
                title: "Thợ Săn Ma",
                subtitle: "Xem \(horrorCount) phim kinh dị",
                date: "Tổng cộng"
            ))
        }
        
        // Total watch time
        let totalMinutes = Int(progressList.reduce(0) { $0 + $1.currentTime }) / 60
        if totalMinutes > 0 && items.count < 5 {
            let hours = totalMinutes / 60
            items.append(AchievementItem(
                iconName: "clock.fill",
                title: "Thời Gian Cày",
                subtitle: hours > 0 ? "Đã xem \(hours) giờ" : "Đã xem \(totalMinutes) phút",
                date: "Tổng cộng"
            ))
        }
        
        // Total movies
        if history.count > 0 && items.count < 6 {
            items.append(AchievementItem(
                iconName: "film.fill",
                title: "Movie Buff",
                subtitle: "Đã xem \(history.count) phim",
                date: "Tổng cộng"
            ))
        }
        
        self.achievements = items
    }
    
    // MARK: - Tính toán
    private func calculateValue(for id: String, history: [Movie], progressList: [WatchProgress]) -> Int {
        switch id {
        case "movie_buff", "first_movie": return history.count
        case "marathon", "binge_master": return calculateStreak(history: history, progressList: progressList)
        case "night_owl":
            return progressList.filter {
                let hour = Calendar.current.component(.hour, from: $0.lastWatched)
                return hour >= 22 || hour < 6
            }.count
        case "early_bird":
            return progressList.filter {
                let hour = Calendar.current.component(.hour, from: $0.lastWatched)
                return hour >= 4 && hour < 6
            }.count
        case "horror_expert": return countGenre(history: history, genreId: 27)
        case "comedy_king": return countGenre(history: history, genreId: 35)
        case "drama_master": return countGenre(history: history, genreId: 18)
        case "scifi_explorer": return countGenre(history: history, genreId: 878)
        case "romance_lover": return countGenre(history: history, genreId: 10749)
        case "watch_time": return Int(progressList.reduce(0) { $0 + $1.currentTime }) / 60
        case "christmas":
            return progressList.filter {
                let comp = Calendar.current.dateComponents([.month, .day], from: $0.lastWatched)
                return comp.month == 12 && comp.day == 25
            }.count
        case "halloween":
            return progressList.filter {
                let comp = Calendar.current.dateComponents([.month, .day], from: $0.lastWatched)
                return comp.month == 10 && comp.day == 31
            }.count
        case "valentine":
            return progressList.filter {
                let comp = Calendar.current.dateComponents([.month, .day], from: $0.lastWatched)
                return comp.month == 2 && comp.day == 14
            }.count
        case "new_year":
            return progressList.filter {
                let comp = Calendar.current.dateComponents([.month, .day], from: $0.lastWatched)
                return comp.month == 1 && comp.day == 1
            }.count
        default: return 0
        }
    }
    
    private func countGenre(history: [Movie], genreId: Int) -> Int {
        history.filter { $0.genreIds?.contains(genreId) == true }.count
    }
    
    private func calculateStreak(history: [Movie], progressList: [WatchProgress]) -> Int {
        let sorted = progressList.sorted { $0.lastWatched > $1.lastWatched }
        guard !sorted.isEmpty else { return 0 }
        var streak = 1
        var currentDate = sorted[0].lastWatched
        for i in 1..<sorted.count {
            let nextDate = sorted[i].lastWatched
            let diff = Calendar.current.dateComponents([.hour], from: nextDate, to: currentDate)
            if let hours = diff.hour, hours <= 4 {
                streak += 1
                currentDate = nextDate
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Persistence
    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(userRankData) {
            UserDefaults.standard.set(data, forKey: "ach_userRankData")
        }
        if let data = try? JSONEncoder().encode(progressList) {
            UserDefaults.standard.set(data, forKey: "ach_progressList")
        }
    }
    
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "ach_userRankData"),
           let decoded = try? JSONDecoder().decode(UserRankData.self, from: data) {
            self.userRankData = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "ach_progressList"),
           let decoded = try? JSONDecoder().decode([AchievementProgress].self, from: data) {
            self.progressList = decoded
        }
    }
}