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
    var progress: Double { guard duration > 0 else { return 0 }; return min(currentTime / duration, 1.0) }
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
    @Published var telegramAvatarURL: String? = nil
    @Published var watchedMovies: [Movie] = []
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var showOnboarding: Bool = false
    
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
        if let prog = UserDefaults.standard.data(forKey: "\(prefix)_progress"), let p = try? JSONDecoder().decode([WatchProgress].self, from: prog) { watchProgressList = p }
    }
}

@main
struct AppEntry: App {
    @StateObject var appState = AppState()
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(appState)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                        Task {
                            await NotificationManager.shared.autoCheckFromAppState(appState)
                        }
                    }
            } else {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
    }
}