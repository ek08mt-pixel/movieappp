import SwiftUI

// MARK: - Dữ liệu cho phần "Hành trình của bạn" (Timeline)
struct JourneyStage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let level: String
    let isUnlocked: Bool
    
    // Hàm helper để lấy Icon Shape tương ứng dựa vào Index
    func getIconShape() -> any Shape {
        switch title {
        case "Newbie": return CrownShape()
        case "Enthusiast": return LightningShape()
        case "Fanatic": return FlameShape()
        case "Pro Watcher": return ProCatShape()
        case "Master": return CrownShape()
        case "Legend": return CrownShape()
        default: return CrownShape()
        }
    }
}

// MARK: - Dữ liệu cho phần "Danh hiệu nổi bật" (List View)
struct AchievementItem: Identifiable {
    let id = UUID()
    let iconShape: any Shape
    let title: String
    let subtitle: String
    let date: String
}