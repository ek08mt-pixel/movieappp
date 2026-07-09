import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var homeID = UUID()
    @State private var exploreID = UUID()
    @State private var libraryID = UUID()
    @State private var watchTogetherID = UUID()
    @StateObject private var ostManager = OSTManager.shared
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView().id(homeID).opacity(selectedTab == 0 ? 1 : 0)
                ExploreView().id(exploreID).opacity(selectedTab == 1 ? 1 : 0)
                LibraryView().id(libraryID).opacity(selectedTab == 2 ? 1 : 0)
                WatchTogetherRoomView().id(watchTogetherID).opacity(selectedTab == 3 ? 1 : 0)
            }
            
            if ostManager.isPlaying && selectedTab != 2 {
                VStack {
                    MiniPlayerView().padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: ostManager.isPlaying)
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 36) {
                    LiquidTabIcon(icon: "house.fill", isSelected: selectedTab == 0) {
                        if selectedTab == 0 { homeID = UUID() } else { selectedTab = 0 }
                    }
                    LiquidTabIcon(icon: "safari.fill", isSelected: selectedTab == 1) {
                        if selectedTab == 1 { exploreID = UUID() } else { selectedTab = 1 }
                    }
                    LiquidTabIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 2) {
                        if selectedTab == 2 { libraryID = UUID() } else { selectedTab = 2 }
                    }
                    LiquidTabIcon(icon: "person.2.fill", isSelected: selectedTab == 3) {
                        if selectedTab == 3 { watchTogetherID = UUID() } else { selectedTab = 3 }
                    }
                }
                .padding(.vertical, 14).padding(.horizontal, 28)
                .background(Capsule().fill(.ultraThinMaterial.opacity(0.2)).shadow(color: .black.opacity(0.08), radius: 4, y: 1))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass").font(.system(size: 26, weight: .bold)).foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 14).padding(.horizontal, 20)
                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.2)).shadow(color: .black.opacity(0.08), radius: 4, y: 1))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                }
            }.padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showSearch) { SearchView() }
        .fullScreenCover(isPresented: $ostManager.showOSTView) {
            OSTView()
        }
    }
}

// MiniPlayerView + LiquidTabIcon giữ nguyên như cũ