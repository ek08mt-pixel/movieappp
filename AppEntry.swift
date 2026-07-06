import SwiftUI

class AppState: ObservableObject {
    @Published var favorites: [Movie] = []
    @Published var watchHistory: [Movie] = []
    @Published var isLoggedIn = false
    @Published var email = ""
    @Published var nickname = ""
    @Published var selectedAvatar = "person.circle.fill"
    @Published var avatarImageData: Data?
    
    private let cloudStore = NSUbiquitousKeyValueStore.default
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )
        load()
    }
    
    @objc func cloudChanged(_ notification: Notification) {
        DispatchQueue.main.async { self.load() }
    }
    
    func register(email: String, password: String) {
        self.email = email
        self.isLoggedIn = true
        cloudStore.set(email, forKey: "registeredEmail")
        cloudStore.set(password, forKey: "registeredPassword")
        save()
    }
    
    func login(email: String, password: String) {
        let savedEmail = cloudStore.string(forKey: "registeredEmail") ?? ""
        let savedPassword = cloudStore.string(forKey: "registeredPassword") ?? ""
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
        cloudStore.set(isLoggedIn, forKey: "isLoggedIn")
        cloudStore.set(email, forKey: "email")
        cloudStore.set(nickname, forKey: "nickname")
        cloudStore.set(selectedAvatar, forKey: "avatar")
        cloudStore.set(avatarImageData, forKey: "avatarImage")
        if let fav = try? JSONEncoder().encode(favorites) { cloudStore.set(fav, forKey: "favorites") }
        if let hist = try? JSONEncoder().encode(watchHistory) { cloudStore.set(hist, forKey: "history") }
        cloudStore.synchronize()
    }
    
    func load() {
        isLoggedIn = cloudStore.bool(forKey: "isLoggedIn")
        email = cloudStore.string(forKey: "email") ?? ""
        nickname = cloudStore.string(forKey: "nickname") ?? ""
        selectedAvatar = cloudStore.string(forKey: "avatar") ?? "person.circle.fill"
        avatarImageData = cloudStore.data(forKey: "avatarImage")
        if let fav = cloudStore.data(forKey: "favorites"),
           let f = try? JSONDecoder().decode([Movie].self, from: fav) { favorites = f }
        if let hist = cloudStore.data(forKey: "history"),
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