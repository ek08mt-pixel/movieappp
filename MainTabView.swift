import SwiftUI

// MARK: - MainTabView
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var homeID = UUID()
    @State private var exploreID = UUID()
    @State private var watchTogetherID = UUID()
    @State private var libraryID = UUID()
    @State private var showWatchTogetherRoom = false
    @State private var tabBarVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @StateObject private var ostManager = OSTManager.shared
    @StateObject private var watchService = WatchTogetherService.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            ZStack {
                HomeView().id(homeID).opacity(selectedTab == 0 ? 1 : 0)
                ExploreView().id(exploreID).opacity(selectedTab == 1 ? 1 : 0)
                WatchTogetherRoomView().id(watchTogetherID).opacity(selectedTab == 2 ? 1 : 0)
                LibraryView().id(libraryID).opacity(selectedTab == 3 ? 1 : 0)
            }
            
            // MiniPlayer + TabBar
            VStack(spacing: 0) {
                // MiniPlayer OST
                if ostManager.isPlaying && !showWatchTogetherRoom {
                    MiniPlayerView()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Bottom Accessory (nhạc mini + search)
                if !showWatchTogetherRoom {
                    HStack(spacing: 12) {
                        // Tab bar chính
                        HStack(spacing: 0) {
                            TabButton(icon: "house.fill", label: "Home", isSelected: selectedTab == 0) {
                                if selectedTab == 0 { homeID = UUID() } else { selectedTab = 0 }
                            }
                            TabButton(icon: "safari.fill", label: "Explore", isSelected: selectedTab == 1) {
                                if selectedTab == 1 { exploreID = UUID() } else { selectedTab = 1 }
                            }
                            TabButton(icon: "person.3.fill", label: "Watch", isSelected: selectedTab == 2) {
                                if selectedTab == 2 { watchTogetherID = UUID() } else { selectedTab = 2 }
                            }
                            TabButton(icon: "rectangle.stack.fill", label: "Library", isSelected: selectedTab == 3) {
                                if selectedTab == 3 { libraryID = UUID() } else { selectedTab = 3 }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial.opacity(0.6))
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.12), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                        )
                        
                        // Nút Search
                        Button {
                            showSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial.opacity(0.6))
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.12), lineWidth: 0.5)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .offset(y: tabBarVisible ? 0 : 120)
                    .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: tabBarVisible)
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.spring(response: 0.4), value: showWatchTogetherRoom)
        .animation(.spring(response: 0.35), value: ostManager.isPlaying)
        .sheet(isPresented: $showSearch) { SearchView() }
        .fullScreenCover(isPresented: $ostManager.showOSTView) { OSTView() }
        .onChange(of: watchService.isInRoom) { inRoom in
            withAnimation { showWatchTogetherRoom = inRoom }
        }
    }
}

// MARK: - Tab Button (iOS 26 style)
struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button {
            withAnimation(.interpolatingSpring(stiffness: 500, damping: 10)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.interpolatingSpring(stiffness: 500, damping: 10)) { isPressed = false }
            }
            action()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(.white.opacity(0.25))
                            .frame(width: 52, height: 32)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                        .scaleEffect(isSelected ? 1.0 : 0.9)
                }
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.45))
            .frame(width: 64)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.interpolatingSpring(stiffness: 500, damping: 10), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}