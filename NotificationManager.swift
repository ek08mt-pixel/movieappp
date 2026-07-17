import UserNotifications
import BackgroundTasks
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    init() {
        requestPermission()
    }
    
    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { self.isAuthorized = granted }
        }
    }
    
    // MARK: - Auto Check từ AppState (không cần nút theo dõi)
    func autoCheckFromAppState(_ appState: AppState) async {
        // Gộp tất cả phim đã tương tác
        var allMovies: [Movie] = []
        allMovies.append(contentsOf: appState.favorites)
        allMovies.append(contentsOf: appState.watchHistory)
        allMovies.append(contentsOf: appState.watchedMovies)
        
        // Lọc trùng + chỉ lấy TV shows
        let uniqueTVShows = Array(Set(allMovies.filter { $0.mediaType == "tv" }))
        
        // Nếu không có phim TV nào → bắn thông báo phim hot
        if uniqueTVShows.isEmpty {
            if let trending = try? await APIService.shared.trending24h(),
               let hotMovie = trending.first {
                await MainActor.run {
                    scheduleHotMovieNotification(movie: hotMovie)
                }
            }
            return
        }
        
        // Check tập mới cho từng phim TV đã xem (tối đa 5 phim)
        for show in uniqueTVShows.prefix(5) {
            do {
                let seasons = (try? await APIService.shared.fetchTVSeasons(tvId: show.id)) ?? []
                guard let lastSeason = seasons.last?.seasonNumber else { continue }
                let detail = try await APIService.shared.fetchSeasonDetail(tvId: show.id, seasonNumber: lastSeason)
                guard let lastEp = detail.episodes.last?.episodeNumber else { continue }
                
                let savedKey = "lastNotified_\(show.id)"
                let lastNotified = UserDefaults.standard.integer(forKey: savedKey)
                
                if lastEp > lastNotified {
                    UserDefaults.standard.set(lastEp, forKey: savedKey)
                    await MainActor.run {
                        scheduleEpisodeNotification(
                            showTitle: show.title,
                            episode: lastEp,
                            season: lastSeason,
                            posterPath: show.posterPath
                        )
                    }
                }
            } catch { continue }
        }
    }
    
    // MARK: - Schedule Notifications
    func scheduleEpisodeNotification(showTitle: String, episode: Int, season: Int, posterPath: String?, delay: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = "Tập mới đã có!"
        content.body = "\(showTitle) - S\(season):E\(episode) vừa ra mắt"
        content.sound = .default
        content.badge = (UIApplication.shared.applicationIconBadgeNumber + 1) as NSNumber
        
        if let poster = posterPath, let url = URL(string: "https://image.tmdb.org/t/p/w200\(poster)") {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".jpg")
                    try? data.write(to: fileURL)
                    if let attachment = try? UNNotificationAttachment(identifier: "poster", url: fileURL) {
                        content.attachments = [attachment]
                    }
                }
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }.resume()
        } else {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func scheduleHotMovieNotification(movie: Movie, delay: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = "Phim hot vừa cập nhật!"
        content.body = "\(movie.title) ⭐ \(movie.ratingText)/10 - Xem ngay!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}