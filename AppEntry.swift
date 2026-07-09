import SwiftUI

// MARK: - Watch Progress Model
struct WatchProgress: Codable, Equatable {
    let movieId: Int
    let movieTitle: String
    let posterPath: String?
    let mediaType: String?
    var season: Int?
    var episode: Int?
    var currentTime: Double
    var duration: Double
    var lastWatched: Date
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(currentTime / duration, 1.0)
    }
}

// MARK: - AppState
class AppState: ObservableObject {
    @Published var favorites: [Movie] = []
    @Published var watchHistory: [Movie] = []
    @Published var watchProgressList: [WatchProgress] = []
    @Published var isLoggedIn = false
    @Published var email = ""
    @Published var nickname = ""
    @Published var selectedAvatar = "person.circle.fill"
    @Published var avatarImageData: Data?
    
    init() { load() }
    
    func register(email: String, password: String) {
        var accounts = getAllAccounts()
        accounts[email] = password
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: "allAccounts")
        }
        self.email = email
        self.isLoggedIn = true
        self.favorites = []
        self.watchHistory = []
        self.watchProgressList = []
        save()
        UserDefaults.standard.set(email, forKey: "lastLoggedInEmail")
    }
    
    func login(email: String, password: String) {
        let accounts = getAllAccounts()
        if let savedPassword = accounts[email], savedPassword == password {
            self.email = email
            self.isLoggedIn = true
            load()
            UserDefaults.standard.set(email, forKey: "lastLoggedInEmail")
        }
    }
    
    func smartLogin(email: String, password: String) {
        let accounts = getAllAccounts()
        if let savedPassword = accounts[email] {
            if savedPassword == password {
                self.email = email
                self.isLoggedIn = true
                load()
                UserDefaults.standard.set(email, forKey: "lastLoggedInEmail")
            }
        } else {
            var newAccounts = accounts
            newAccounts[email] = password
            if let data = try? JSONEncoder().encode(newAccounts) {
                UserDefaults.standard.set(data, forKey: "allAccounts")
            }
            self.email = email
            self.isLoggedIn = true
            self.favorites = []
            self.watchHistory = []
            self.watchProgressList = []
            save()
            UserDefaults.standard.set(email, forKey: "lastLoggedInEmail")
        }
    }
    
    private func getAllAccounts() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: "allAccounts"),
              let accounts = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return accounts
    }
    
    func logout() {
        isLoggedIn = false
        email = ""
        nickname = ""
        selectedAvatar = "person.circle.fill"
        avatarImageData = nil
        favorites = []
        watchHistory = []
        watchProgressList = []
        save()
        UserDefaults.standard.removeObject(forKey: "lastLoggedInEmail")
    }
    
    func updateProgress(_ progress: WatchProgress) {
        watchProgressList.removeAll { $0.movieId == progress.movieId && $0.season == progress.season && $0.episode == progress.episode }
        watchProgressList.insert(progress, at: 0)
        if watchProgressList.count > 30 { watchProgressList.removeLast() }
        save()
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
    }
    
    func load() {
        // Khôi phục email từ lần đăng nhập trước
        let savedEmail = UserDefaults.standard.string(forKey: "lastLoggedInEmail") ?? ""
        if !savedEmail.isEmpty {
            self.email = savedEmail
        }
        
        let prefix = email.isEmpty ? "default" : email.replacingOccurrences(of: ".", with: "_").replacingOccurrences(of: "@", with: "_")
        isLoggedIn = UserDefaults.standard.bool(forKey: "\(prefix)_isLoggedIn")
        email = UserDefaults.standard.string(forKey: "\(prefix)_email") ?? ""
        nickname = UserDefaults.standard.string(forKey: "\(prefix)_nickname") ?? ""
        selectedAvatar = UserDefaults.standard.string(forKey: "\(prefix)_avatar") ?? "person.circle.fill"
        avatarImageData = UserDefaults.standard.data(forKey: "\(prefix)_avatarImage")
        if let fav = UserDefaults.standard.data(forKey: "\(prefix)_favorites"),
           let f = try? JSONDecoder().decode([Movie].self, from: fav) { favorites = f }
        if let hist = UserDefaults.standard.data(forKey: "\(prefix)_history"),
           let h = try? JSONDecoder().decode([Movie].self, from: hist) { watchHistory = h }
        if let prog = UserDefaults.standard.data(forKey: "\(prefix)_progress"),
           let p = try? JSONDecoder().decode([WatchProgress].self, from: prog) { watchProgressList = p }
    }
}

@main
struct AppEntry: App {
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            SplashView().environmentObject(appState)
        }
    }
}