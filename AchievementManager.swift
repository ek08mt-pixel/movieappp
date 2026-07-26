import SwiftUI

class AchievementManager: ObservableObject {
    // Dữ liệu Hành trình
    @Published var journeyStages: [JourneyStage] = [
        JourneyStage(title: "Newbie", level: "Lv.1", isUnlocked: true),
        JourneyStage(title: "Enthusiast", level: "Lv.5", isUnlocked: true),
        JourneyStage(title: "Fanatic", level: "Lv.10", isUnlocked: true),
        JourneyStage(title: "Pro Watcher", level: "Lv.12", isUnlocked: true), // Active
        JourneyStage(title: "Master", level: "Lv.15", isUnlocked: false),
        JourneyStage(title: "Legend", level: "Lv.20", isUnlocked: false)
    ]
    
    // Dữ liệu Danh hiệu nổi bật
    @Published var achievements: [AchievementItem] = [
        AchievementItem(
            iconShape: LightningShape(),
            title: "Cú Đêm Chính Hiệu",
            subtitle: "Xem phim từ 23:00 đến 3:00",
            date: "12.05.2024"
        ),
        AchievementItem(
            iconShape: FlameShape(),
            title: "Binge Master",
            subtitle: "Xem liên tục 5 tập phim",
            date: "08.05.2024"
        ),
        AchievementItem(
            iconShape: MasksShape(),
            title: "Drama Queen",
            subtitle: "Xem 10 phim thể loại Drama",
            date: "02.05.2024"
        )
    ]
}