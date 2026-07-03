import SwiftUI

class AppState: ObservableObject {
    @Published var favorites: [Movie] = []
    @Published var watchHistory: [Movie] = []
    @Published var searchHistory: [String] = []
    @Published var isLoggedIn = false
    @Published var userName = ""
}

@main
struct EmmewApp: App {
    @StateObject private var appState = AppState()
    @State private var showSplash = true
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                MainTabView()
                    .environmentObject(appState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
