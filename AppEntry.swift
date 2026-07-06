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
        self.email = email
        self.isLoggedIn = true
        UserDefaults.standard.set(email, forKey: "registeredEmail")
        UserDefaults.standard.set(password, forKey: "registeredPassword")
        save()
    }
    
    func login(email: String, password: String) {
        let savedEmail = UserDefaults.standard.string(forKey: "registeredEmail") ?? ""
        let savedPassword = UserDefaults.standard.string(forKey: "registeredPassword") ?? ""
        if email == savedEmail && password == savedPassword {
            self.email = email
            self.isLoggedIn = true
            load()
        }
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
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(nickname, forKey: "nickname")
        UserDefaults.standard.set(selectedAvatar, forKey: "avatar")
        UserDefaults.standard.set(avatarImageData, forKey: "avatarImage")
        if let fav = try? JSONEncoder().encode(favorites) { UserDefaults.standard.set(fav, forKey: "favorites") }
        if let hist = try? JSONEncoder().encode(watchHistory) { UserDefaults.standard.set(hist, forKey: "history") }
    }
    
    func load() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        email = UserDefaults.standard.string(forKey: "email") ?? ""
        nickname = UserDefaults.standard.string(forKey: "nickname") ?? ""
        selectedAvatar = UserDefaults.standard.string(forKey: "avatar") ?? "person.circle.fill"
        avatarImageData = UserDefaults.standard.data(forKey: "avatarImage")
        if let fav = UserDefaults.standard.data(forKey: "favorites"),
           let f = try? JSONDecoder().decode([Movie].self, from: fav) { favorites = f }
        if let hist = UserDefaults.standard.data(forKey: "history"),
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