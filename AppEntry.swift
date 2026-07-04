import SwiftUI
import AVFoundation

class AppState: ObservableObject {
    @Published var favorites: [Movie] = []
    @Published var watchHistory: [Movie] = []
    @Published var searchHistory: [String] = []
    @Published var isLoggedIn = false
    @Published var userName = ""
    @Published var selectedAvatar = "person.fill"
    
    init() { loadFromDisk() }
    func saveToDisk() {
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(selectedAvatar, forKey: "selectedAvatar")
    }
    func loadFromDisk() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        selectedAvatar = UserDefaults.standard.string(forKey: "selectedAvatar") ?? "person.fill"
    }
}

@main
struct EmmewApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var langManager = LanguageManager.shared
    @State private var showSplash = true
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        NotificationManager.shared.requestPermission()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .allowAirPlay)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView()
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation(.easeOut(duration: 0.5)) { showSplash = false } } }
            } else {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(langManager)
                    .preferredColorScheme(.dark)
            }
        }
    }
}