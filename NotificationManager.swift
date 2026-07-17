import UserNotifications
import BackgroundTasks

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var followedShows: [Int: (title: String, lastSeason: Int, lastEpisode: Int, posterPath: String?, mediaType: String?)] = [:]
    
    private let followedKey = "followedShows"
    
    init() {
        loadFollowedShows()
    }
    
    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { self.isAuthorized = granted }
        }
    }
    
    // MARK: - Follow Shows
    func toggleFollow(movieId: Int, title: String, season: Int, episode: Int, posterPath: String?, mediaType: String?) {
        if followedShows[movieId] != nil {
            followedShows.removeValue(forKey: movieId)
        } else {
            followedShows[movieId] = (title: title, lastSeason: season, lastEpisode: episode, posterPath: posterPath, mediaType: mediaType)
        }
        saveFollowedShows()
    }
    
    func isFollowing(movieId: Int) -> Bool {
        followedShows[movieId] != nil
    }
    
    private func saveFollowedShows() {
        let data = try? JSONEncoder().encode(followedShows.mapValues { FollowedShowData(title: $0.title, lastSeason: $0.lastSeason, lastEpisode: $0.lastEpisode, posterPath: $0.posterPath, mediaType: $0.mediaType) })
        UserDefaults.standard.set(data, forKey: followedKey)
    }
    
    private func loadFollowedShows() {
        guard let data = UserDefaults.standard.data(forKey: followedKey),
              let decoded = try? JSONDecoder().decode([Int: FollowedShowData].self, from: data) else { return }
        followedShows = decoded.mapValues { (title: $0.title, lastSeason: $0.lastSeason, lastEpisode: $0.lastEpisode, posterPath: $0.posterPath, mediaType: $0.mediaType) }
    }
    
    // MARK: - Check New Episodes
    func checkNewEpisodes() async {
        for (movieId, show) in followedShows {
            guard let mediaType = show.mediaType else { continue }
            
            var currentSeason = show.lastSeason
            var currentEpisode = show.lastEpisode
            var hasNewEpisode = false
            
            do {
                if mediaType == "tv" {
                    let detail = try await APIService.shared.fetchSeasonDetail(tvId: movieId, seasonNumber: currentSeason)
                    let lastEp = detail.episodes.last?.episodeNumber ?? currentEpisode
                    if lastEp > currentEpisode {
                        currentEpisode = lastEp
                        hasNewEpisode = true
                    }
                } else {
                    // Phim lẻ - check xem có phần mới không
                    let detail = try? await APIService.shared.movieDetail(movieId: movieId)
                    if let collectionId = detail?.belongsToCollection?.id,
                       let collection = try? await APIService.shared.collectionDetail(collectionId: collectionId) {
                        let latestPart = collection.parts.sorted { ($0.releaseDate ?? "") < ($1.releaseDate ?? "") }.last
                        if let latest = latestPart, latest.id != movieId {
                            hasNewEpisode = true
                        }
                    }
                }
            } catch { continue }
            
            if hasNewEpisode {
                await MainActor.run {
                    followedShows[movieId]?.lastEpisode = currentEpisode
                    scheduleEpisodeNotification(showTitle: show.title, episode: currentEpisode, season: currentSeason, posterPath: show.posterPath)
                }
                saveFollowedShows()
            }
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
    
    // MARK: - Background Check
    func scheduleBackgroundCheck() {
        let request = BGAppRefreshTaskRequest(identifier: "com.emmew.checkNewEpisodes")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}

// MARK: - Codable Helper
struct FollowedShowData: Codable {
    let title: String
    let lastSeason: Int
    let lastEpisode: Int
    let posterPath: String?
    let mediaType: String?
}