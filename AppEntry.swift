import SwiftUI
import Security

// MARK: - Keychain Helper
struct KeychainHelper {
    static func save(key: String, data: Data) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key,
                                     kSecValueData as String: data]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key,
                                     kSecReturnData as String: true,
                                     kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &item)
        return item as? Data
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Watch Progress Model
struct WatchProgress: Codable, Equatable {
    let movieId: Int; let movieTitle: String; let posterPath: String?; let mediaType: String?
    var season: Int?; var episode: Int?; var currentTime: Double; var duration: Double; var lastWatched: Date
    var source: String? = nil
    var imdbID: String? = nil
    var lastKnownEpisode: Int? = nil
    var seenNewEpisodeBadge: Bool = false
    var progress: Double { guard duration > 0 else { return 0 }; return min(currentTime / duration, 1.0) }
    
    enum CodingKeys: String, CodingKey {
        case movieId, movieTitle, posterPath, mediaType
        case season, episode, currentTime, duration, lastWatched
        case source, imdbID, lastKnownEpisode, seenNewEpisodeBadge
    }
    
    init(movieId: Int, movieTitle: String, posterPath: String?, mediaType: String?,
         season: Int?, episode: Int?, currentTime: Double, duration: Double, lastWatched: Date,
         source: String? = nil, imdbID: String? = nil,
         lastKnownEpisode: Int? = nil, seenNewEpisodeBadge: Bool = false) {
        self.movieId = movieId; self.movieTitle = movieTitle
        self.posterPath = posterPath; self.mediaType = mediaType
        self.season = season; self.episode = episode
        self.currentTime = currentTime; self.duration = duration
        self.lastWatched = lastWatched
        self.source = source; self.imdbID = imdbID
        self.lastKnownEpisode = lastKnownEpisode
        self.seenNewEpisodeBadge = seenNewEpisodeBadge
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        movieId = try c.decode(Int.self, forKey: .movieId)
        movieTitle = try c.decode(String.self, forKey: .movieTitle)
        posterPath = try c.decodeIfPresent(String.self, forKey: .posterPath)
        mediaType = try c.decodeIfPresent(String.self, forKey: .mediaType)
        season = try c.decodeIfPresent(Int.self, forKey: .season)
        episode = try c.decodeIfPresent(Int.self, forKey: .episode)
        currentTime = try c.decode(Double.self, forKey: .currentTime)
        duration = try c.decode(Double.self, forKey: .duration)
        lastWatched = try c.decode(Date.self, forKey: .lastWatched)
        source = try c.decodeIfPresent(String.self, forKey: .source)
        imdbID = try c.decodeIfPresent(String.self, forKey: .imdbID)
        lastKnownEpisode = try c.decodeIfPresent(Int.self, forKey: .lastKnownEpisode)
        seenNewEpisodeBadge = try c.decodeIfPresent(Bool.self, forKey: .seenNewEpisodeBadge) ?? false
    }
}

struct MovieList: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var name: String
    var movies: [Movie] = []
    var createdAt: Date = Date()
}

// MARK: - AppState
class AppState: ObservableObject {
    @Published var favorites: [Movie] = []
    @Published var watchHistory: [Movie] = []
    @Published var watchProgressList: [WatchProgress] = []
    @Published var newEpisodeMap: [Int: Int] = [:]   // movieId -> số tập mới nhất
    @Published var isLoggedIn = false
    @Published var email = ""
    @Published var nickname = ""
    @Published var selectedAvatar = "person.circle.fill"
    @Published var avatarImageData: Data?
    @Published var telegramAvatarURL: String? = nil
    @Published var watchedMovies: [Movie] = []
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var showOnboarding: Bool = false
    
    @Published var notificationMovieId: Int?
    @Published var showNotificationMovie = false
    @Published var movieLists: [MovieList] = []
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        load()
    }
    
    func register(email: String, password: String) {
        var accounts = getAllAccounts(); accounts[email] = password; saveAllAccounts(accounts)
        self.email = email; self.isLoggedIn = true; self.favorites = []; self.watchHistory = []; self.watchProgressList = []
        save(); saveLastEmail(email)
    }
    
    func login(email: String, password: String) {
        let accounts = getAllAccounts()
        if let savedPassword = accounts[email], savedPassword == password {
            self.email = email; self.isLoggedIn = true
            save(); saveLastEmail(email)
        }
    }
    
    func smartLogin(email: String, password: String) {
        let accounts = getAllAccounts()
        if let savedPassword = accounts[email] {
            if savedPassword == password {
                self.email = email; self.isLoggedIn = true
                save(); saveLastEmail(email)
            }
        } else {
            var newAccounts = accounts; newAccounts[email] = password; saveAllAccounts(newAccounts)
            self.email = email; self.isLoggedIn = true; self.favorites = []; self.watchHistory = []; self.watchProgressList = []
            save(); saveLastEmail(email)
        }
    }
    
    func telegramLogin(telegramId: String, name: String, avatarURL: String?) {
        self.email = "tg_\(telegramId)"; self.nickname = name; self.telegramAvatarURL = avatarURL
        self.isLoggedIn = true; save()
        if let data = email.data(using: .utf8) { KeychainHelper.save(key: "lastLoggedInEmail", data: data) }
    }
    
    private func saveAllAccounts(_ accounts: [String: String]) {
        if let data = try? JSONEncoder().encode(accounts) { KeychainHelper.save(key: "allAccounts", data: data) }
    }
    
    private func getAllAccounts() -> [String: String] {
        guard let data = KeychainHelper.load(key: "allAccounts"), let accounts = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return accounts
    }
    
    private func saveLastEmail(_ email: String) {
        if let data = email.data(using: .utf8) { KeychainHelper.save(key: "lastLoggedInEmail", data: data) }
    }
    
    func logout() {
        isLoggedIn = false; email = ""; nickname = ""; selectedAvatar = "person.circle.fill"
        avatarImageData = nil; telegramAvatarURL = nil; favorites = []; watchHistory = []; watchProgressList = []
        hasCompletedOnboarding = false
        save()
    }
    
    func updateProgress(_ progress: WatchProgress) {
        watchProgressList.removeAll { $0.movieId == progress.movieId }
        watchProgressList.insert(progress, at: 0)
        if watchProgressList.count > 30 { watchProgressList.removeLast() }
        // Nếu là tập mới nhất đã xem → cập nhật lastKnownEpisode nếu cao hơn
        if let ep = progress.episode {
            if let idx = watchProgressList.firstIndex(where: { $0.movieId == progress.movieId }) {
                let current = watchProgressList[idx].lastKnownEpisode ?? 0
                if ep > current { watchProgressList[idx].lastKnownEpisode = ep }
            }
        }
        save()
    }
    
    // Gọi khi user bấm xem tập mới từ badge → ẩn badge
    func markBadgeSeen(movieId: Int) {
        guard let idx = watchProgressList.firstIndex(where: { $0.movieId == movieId }) else { return }
        watchProgressList[idx].seenNewEpisodeBadge = true
        newEpisodeMap.removeValue(forKey: movieId)
        save()
    }
    
    // Gọi sau khi check API xong: nếu có tập mới hơn lastKnownEpisode → set badge
    func setNewEpisodeIfNeeded(movieId: Int, latestEpisode: Int) {
        guard let idx = watchProgressList.firstIndex(where: { $0.movieId == movieId }) else { return }
        let known = watchProgressList[idx].lastKnownEpisode ?? 0
        if latestEpisode > known {
            watchProgressList[idx].seenNewEpisodeBadge = false
            newEpisodeMap[movieId] = latestEpisode
        } else {
            watchProgressList[idx].seenNewEpisodeBadge = true
            newEpisodeMap.removeValue(forKey: movieId)
        }
        save()
    }
    
    func hasNewEpisode(movieId: Int) -> Bool {
        return newEpisodeMap[movieId] != nil && !(watchProgressList.first(where: { $0.movieId == movieId })?.seenNewEpisodeBadge ?? true)
    }
    
    func latestNewEpisode(movieId: Int) -> Int? {
        return newEpisodeMap[movieId]
    }
    
    func save() {
        let prefix = email.isEmpty ? "default" : email.replacingOccurrences(of: ".", with: "_").replacingOccurrences(of: "@", with: "_")
        UserDefaults.standard.set(isLoggedIn, forKey: "\(prefix)_isLoggedIn")
        UserDefaults.standard.set(email, forKey: "\(prefix)_email")
        UserDefaults.standard.set(nickname, forKey: "\(prefix)_nickname")
        UserDefaults.standard.set(selectedAvatar, forKey: "\(prefix)_avatar")
        UserDefaults.standard.set(avatarImageData, forKey: "\(prefix)_avatarImage")
        if let fav = try? JSONEncoder().encode(favorites) { UserDefaults.standard.set(fav, forKey: "\(prefix)_favorites") }
        if let hist = try? JSONEncoder().encode(watchHistory) { UserDefaults.standard.set(hist, forKey: "\(prefix)_history") }
        if let prog = try? JSONEncoder().encode(watchProgressList) { UserDefaults.standard.set(prog, forKey: "\(prefix)_progress") }
        if let lists = try? JSONEncoder().encode(movieLists) { UserDefaults.standard.set(lists, forKey: "\(prefix)_movieLists") }
    }

    
    func load() {
        let savedEmailData = KeychainHelper.load(key: "lastLoggedInEmail")
        let savedEmail = savedEmailData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        if !savedEmail.isEmpty { self.email = savedEmail }
        
        let prefix = email.isEmpty ? "default" : email.replacingOccurrences(of: ".", with: "_").replacingOccurrences(of: "@", with: "_")
        isLoggedIn = UserDefaults.standard.bool(forKey: "\(prefix)_isLoggedIn")
        nickname = UserDefaults.standard.string(forKey: "\(prefix)_nickname") ?? ""
        selectedAvatar = UserDefaults.standard.string(forKey: "\(prefix)_avatar") ?? "person.circle.fill"
        avatarImageData = UserDefaults.standard.data(forKey: "\(prefix)_avatarImage")
        if let fav = UserDefaults.standard.data(forKey: "\(prefix)_favorites"), let f = try? JSONDecoder().decode([Movie].self, from: fav) { favorites = f }
        if let hist = UserDefaults.standard.data(forKey: "\(prefix)_history"), let h = try? JSONDecoder().decode([Movie].self, from: hist) { watchHistory = h }
        if let prog = UserDefaults.standard.data(forKey: "\(prefix)_progress"), let p = try? JSONDecoder().decode([WatchProgress].self, from: prog) {
            watchProgressList = p
            // Rebuild newEpisodeMap từ dữ liệu đã lưu
            newEpisodeMap.removeAll()
            for wp in p {
                if wp.seenNewEpisodeBadge == false, let known = wp.lastKnownEpisode {
                    newEpisodeMap[wp.movieId] = known
                }
            }
        }
        if let lists = UserDefaults.standard.data(forKey: "\(prefix)_movieLists"), let l = try? JSONDecoder().decode([MovieList].self, from: lists) { movieLists = l }
    }
}

// MARK: - AppDelegate for Notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let movieId = response.notification.request.content.userInfo["movieId"] as? Int {
            NotificationCenter.default.post(name: Notification.Name("OpenMovieFromNotification"), object: nil, userInfo: ["movieId": movieId])
        }
        completionHandler()
    }
}

// MARK: - App Entry
@main
struct AppEntry: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appState = AppState()
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("userTheme") var userTheme: String = "dark"
    @State private var showSplash = true
    
    init() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        URLProtocol.registerClass(CustomURLProtocol.self)
    }
    
    private func checkNewEpisodesOnLaunch() async {
        let list = appState.watchProgressList
        guard !list.isEmpty else { return }
        for wp in list {
            let latest = await fetchLatestEpisodeCount(for: wp)
            if let latest = latest, latest > 0 {
                await MainActor.run {
                    appState.setNewEpisodeIfNeeded(movieId: wp.movieId, latestEpisode: latest)
                }
            }
        }
    }
    
    private func fetchLatestEpisodeCount(for wp: WatchProgress) async -> Int? {
        // Chỉ check phim bộ
        guard wp.mediaType == "tv" || wp.season != nil else { return nil }
        let season = wp.season ?? 1
        
        // Ưu tiên: dùng imdbID đã lưu + source để gọi đúng service
        if let imdb = wp.imdbID, !imdb.isEmpty {
            switch wp.source {
            case "Emew 2":
                if let slug = MappingCache.shared.getNguonCSlug(imdbID: imdb) {
                    return await NguonCEpisodeCounter.shared.fetchEpisodeCount(slug: slug, season: season)
                }
            case "Emew 3":
                if let slug = MappingCache.shared.getVSMOVSlug(imdbID: imdb) {
                    return await VSMOVEEpisodeCounter.shared.fetchEpisodeCount(slug: slug, season: season)
                }
            default:
                break
            }
        }
        
        // Fallback: dùng directSlug + PhimAPIService.fetchRawEpisodes
        if let slug = MappingCache.getDirectSlug(tmdbID: wp.movieId, season: season) {
            return await PhimEpisodeCounter.shared.fetchEpisodeCount(slug: slug, season: season)
        }
        if let animeSlug = MappingCache.getAnimeSlug(tmdbID: wp.movieId) {
            return await PhimEpisodeCounter.shared.fetchEpisodeCount(slug: animeSlug, season: season)
        }
        if let hardcoded = MappingCache.shared.getHardcodedSlug(tmdbID: wp.movieId, season: season) {
            return await PhimEpisodeCounter.shared.fetchEpisodeCount(slug: hardcoded, season: season)
        }
        return nil
    }
    
    var colorScheme: ColorScheme? {
        switch userTheme {
        case "light": return .light
        case "system": return nil
        default: return .dark
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(showSplash: $showSplash)
                        .environmentObject(appState)
                        .transition(.opacity)
                } else if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(appState)
                        .preferredColorScheme(colorScheme)
                        .task {
                            await checkNewEpisodesOnLaunch()
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                            Task {
                                await NotificationManager.shared.autoCheckFromAppState(appState)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenMovieFromNotification"))) { notification in
                            if let movieId = notification.userInfo?["movieId"] as? Int {
                                appState.notificationMovieId = movieId
                                appState.showNotificationMovie = true
                            }
                        }
                        .sheet(isPresented: $appState.showNotificationMovie) {
                            if let movieId = appState.notificationMovieId {
                                MovieDetailView(movie: Movie(id: movieId, title: "", overview: "", posterPath: nil, backdropPath: nil, voteAverage: 0, releaseDate: nil, genreIds: nil, originalTitle: nil, popularity: nil, voteCount: nil, adult: false, originalLanguage: nil, mediaType: nil))
                            }
                        }
                } else {
                    OnboardingView(appState: appState)
                        .environmentObject(appState)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
        }
    }
}