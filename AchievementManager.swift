import SwiftUI

// MARK: - Achievement Manager
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var userRankData = UserRankData(totalXP: 0, unlockedAchievements: 0, totalAchievements: 0)
    @Published var progressList: [AchievementProgress] = []
    
    private let achievements = AchievementData.all
    
    init() {
        loadFromUserDefaults()
    }
    
    // MARK: - Public
    func refresh(from appState: AppState) {
        let history = appState.watchHistory
        let progress = appState.watchProgressList
        
        // Tính XP
        var xp = 0
        xp += history.count * 10 // 10 XP mỗi phim xem
        xp += appState.favorites.count * 5
        xp += appState.watchedMovies.count * 5
        xp += Int(progress.reduce(0) { $0 + $1.currentTime }) / 60 // 1 XP mỗi phút xem
        
        // Tính achievement progress
        var newProgressList: [AchievementProgress] = []
        
        for ach in achievements {
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
        let totalCount = achievements.reduce(0) { $0 + $1.tiers.count }
        
        self.progressList = newProgressList
        self.userRankData = UserRankData(
            totalXP: xp,
            unlockedAchievements: unlockedCount,
            totalAchievements: totalCount
        )
        
        saveToUserDefaults()
    }
    
    func progress(for achievementId: String) -> AchievementProgress? {
        progressList.first(where: { $0.achievementId == achievementId })
    }
    
    // MARK: - Tính toán từng loại
    private func calculateValue(for id: String, history: [Movie], progressList: [WatchProgress]) -> Int {
        switch id {
        case "movie_buff", "first_movie":
            return history.count
        
        case "marathon":
            return calculateStreak(history: history, progressList: progressList)
        
        case "binge_master":
            return calculateStreak(history: history, progressList: progressList)
        
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
        
        case "horror_expert":
            return countGenre(history: history, genreId: 27) // Horror
        
        case "comedy_king":
            return countGenre(history: history, genreId: 35) // Comedy
        
        case "drama_master":
            return countGenre(history: history, genreId: 18) // Drama
        
        case "scifi_explorer":
            return countGenre(history: history, genreId: 878) // Sci-Fi
        
        case "romance_lover":
            return countGenre(history: history, genreId: 10749) // Romance
        
        case "watch_time":
            return Int(progressList.reduce(0) { $0 + $1.currentTime }) / 60 // Tổng phút
        
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
        
        default:
            return 0
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