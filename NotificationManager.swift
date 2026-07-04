import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    func requestPermission() { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in } }
    func scheduleNewMovieNotification(movie: Movie) {
        let content = UNMutableNotificationContent(); content.title = "🎬 Phim hot: \(movie.title)"; content.body = "⭐ \(movie.ratingText)/10 - Xem ngay!"; content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: movie.title, content: content, trigger: trigger))
    }
}