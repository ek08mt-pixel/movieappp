import SwiftUI

class AppState: ObservableObject {
    @Published var favorites: [Movie] = []
    @Published var watchHistory: [Movie] = []
    @Published var isLoggedIn = false
    @Published var email = ""
    @Published var nickname = ""
    @Published var selectedAvatar = "person.circle.fill"
    @Published var avatarImageData: Data?
    
    init() { load() }
    
    func register(email: String, password: String) {
        // Lưu tài khoản mới vào danh sách
        var accounts = getAllAccounts()
        accounts[email] = password
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: "allAccounts")
        }
        // Tự động đăng nhập
        self.email = email
        self.isLoggedIn = true
        self.favorites = []
        self.watchHistory = []
        save()
    }
    
    func login(email: String, password: String) {
        let accounts = getAllAccounts()
        if let savedPassword = accounts[email], savedPassword == password {
            self.email = email
            self.isLoggedIn = true
            load() // Load dữ liệu của tài khoản này
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
    }
    
    func load() {
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