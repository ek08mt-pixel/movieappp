import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var homeID = UUID()
    @State private var exploreID = UUID()
    @State private var libraryID = UUID()
    @State private var profileID = UUID()
    @StateObject private var ostManager = OSTManager.shared
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView().id(homeID).opacity(selectedTab == 0 ? 1 : 0)
                ExploreView().id(exploreID).opacity(selectedTab == 1 ? 1 : 0)
                // LibraryView().id(libraryID).opacity(selectedTab == 2 ? 1 : 0)
                // ProfileView().id(profileID).opacity(selectedTab == 3 ? 1 : 0)
            }
            
            if ostManager.isPlaying && selectedTab != 2 {
                VStack {
                    MiniPlayerView().padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            HStack(spacing: 10) {
                HStack(spacing: 31) {
                    LiquidTabIcon(icon: "house.fill", label: "Home", isSelected: selectedTab == 0) {
                        if selectedTab == 0 { homeID = UUID() } else { selectedTab = 0 }
                    }
                    LiquidTabIcon(icon: "safari.fill", label: "Explore", isSelected: selectedTab == 1) {
                        if selectedTab == 1 { exploreID = UUID() } else { selectedTab = 1 }
                    }
                    LiquidTabIcon(icon: "rectangle.stack.fill", label: "Library", isSelected: selectedTab == 2) {
                        if selectedTab == 2 { libraryID = UUID() } else { selectedTab = 2 }
                    }
                    LiquidTabIcon(icon: "person.fill", label: "Me", isSelected: selectedTab == 3) {
                        if selectedTab == 3 { profileID = UUID() } else { selectedTab = 3 }
                    }
                }
                .padding(.vertical, 12).padding(.horizontal, 24)
                .background(Capsule().fill(.ultraThinMaterial.opacity(0.35)).overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.3)))
                
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass").font(.system(size: 22, weight: .medium)).foregroundColor(.white.opacity(0.7)).padding(.vertical, 21).padding(.horizontal, 19)
                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.35)).overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.3)))
                }
            }
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard)
        .animation(.spring(response: 0.4), value: selectedTab)
        .sheet(isPresented: $showSearch) { SearchView() }
        .fullScreenCover(isPresented: $ostManager.showOSTView) { OSTView() }
    }
}