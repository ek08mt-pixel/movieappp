import SwiftUI

// MARK: - MainTabView
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var homeID = UUID()
    @State private var exploreID = UUID()
    @State private var libraryID = UUID()
    @State private var watchTogetherID = UUID()
    @State private var showWatchTogetherRoom = false
    @StateObject private var ostManager = OSTManager.shared
    @StateObject private var watchService = WatchTogetherService.shared
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView().id(homeID).opacity(selectedTab == 0 ? 1 : 0)
                ExploreView().id(exploreID).opacity(selectedTab == 1 ? 1 : 0)
                LibraryView().id(libraryID).opacity(selectedTab == 2 ? 1 : 0)
                WatchTogetherRoomView().id(watchTogetherID).opacity(selectedTab == 3 ? 1 : 0)
            }
            
            if ostManager.isPlaying && selectedTab != 2 && !showWatchTogetherRoom {
                VStack {
                    MiniPlayerView().padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            if !showWatchTogetherRoom {
                HStack(spacing: 10) {
                    HStack(spacing: 31) {
                        LiquidTabIcon(
                            icon: "house.fill",
                            label: "Home",
                            isSelected: selectedTab == 0
                        ) {
                            if selectedTab == 0 { homeID = UUID() } else { selectedTab = 0 }
                        }
                        LiquidTabIcon(
                            icon: "safari.fill",
                            label: "Explore",
                            isSelected: selectedTab == 1
                        ) {
                            if selectedTab == 1 { exploreID = UUID() } else { selectedTab = 1 }
                        }
                        LiquidTabIcon(
                            icon: "rectangle.stack.fill",
                            label: "Library",
                            isSelected: selectedTab == 2
                        ) {
                            if selectedTab == 2 { libraryID = UUID() } else { selectedTab = 2 }
                        }
                        LiquidTabIcon(
                            icon: "person.3.fill",
                            label: "Watch",
                            isSelected: selectedTab == 3
                        ) {
                            if selectedTab == 3 { watchTogetherID = UUID() } else { selectedTab = 3 }
                        }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.35))
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.1), lineWidth: 0.3)
                            )
                    )
                    
                    Button { showSearch = true } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 12).padding(.horizontal, 22)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial.opacity(0.35))
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(0.1), lineWidth: 0.3)
                                    )
                            )
                    }
                }
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.spring(response: 0.4), value: showWatchTogetherRoom)
        .sheet(isPresented: $showSearch) { SearchView() }
        .fullScreenCover(isPresented: $ostManager.showOSTView) { OSTView() }
        .onChange(of: watchService.isInRoom) { inRoom in
            withAnimation { showWatchTogetherRoom = inRoom }
        }
        .onChange(of: selectedTab) { tab in
            if tab == 3 && watchService.isInRoom { showWatchTogetherRoom = true }
        }
    }
}

// MARK: - MiniPlayerView
struct MiniPlayerView: View {
    @StateObject private var ostManager = OSTManager.shared
    @State private var pulse = false
    
    var body: some View {
        Button {
            if ostManager.miniMode == .dot {
                ostManager.showOSTView = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    let next = (ostManager.miniMode.rawValue + 1) % 3
                    ostManager.miniMode = OSTManager.MiniMode.allCases[next]
                }
            }
        } label: {
            switch ostManager.miniMode {
            case .normal: normalMode
            case .bubble: bubbleMode
            case .dot: dotMode
            }
        }
        .buttonStyle(.plain)
        .onTapGesture(count: 2) { ostManager.showOSTView = true }
    }
    
    var normalMode: some View {
        HStack(spacing: 8) {
            if let poster = ostManager.currentPoster, let url = URL(string: "https://image.tmdb.org/t/p/w200\(poster)") {
                CachedAsyncImage(url: url).aspectRatio(2/3, contentMode: .fill).frame(width: 28, height: 42).clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial.opacity(0.5)).frame(width: 28, height: 42)
                    .overlay(Image(systemName: "music.note").font(.system(size: 10)).foregroundColor(.white.opacity(0.6)))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(ostManager.currentTrack).font(.system(size: 11, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                Text(ostManager.currentMovie).font(.system(size: 9)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
            }
            Spacer()
            Button { ostManager.togglePlayback?() } label: {
                Image(systemName: ostManager.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 11)).foregroundColor(.white)
                    .frame(width: 24, height: 24).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
            }
            Button { withAnimation { ostManager.stopPlayback?() } } label: {
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    .frame(width: 16, height: 16).background(Circle().fill(.ultraThinMaterial.opacity(0.2)))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(width: 260, height: 48)
        .background(RoundedRectangle(cornerRadius: 24).fill(.black.opacity(0.9)).overlay(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial.opacity(0.15))))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
    
    var bubbleMode: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.white.opacity(0.08), .purple.opacity(0.05), .cyan.opacity(0.05), .clear], center: .center, startRadius: 10, endRadius: 50))
                .frame(width: 70, height: 70).blur(radius: 5)
            Circle()
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05), .clear, .white.opacity(0.15), .purple.opacity(0.1), .cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
                .frame(width: 55, height: 55)
                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5).frame(width: 53, height: 53))
            VStack(spacing: 2) {
                Image(systemName: ostManager.isPlaying ? "music.note" : "pause").font(.system(size: 16)).foregroundColor(.white)
                Text(ostManager.currentTrack.components(separatedBy: " ").prefix(1).joined()).font(.system(size: 7, weight: .bold)).foregroundColor(.white)
            }
        }
        .frame(width: 60, height: 60)
        .shadow(color: .white.opacity(0.1), radius: 8)
        .scaleEffect(pulse ? 1.05 : 1)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
    
    var dotMode: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial.opacity(0.8)).frame(width: 14, height: 14)
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 0.5))
            if ostManager.isPlaying {
                HStack(spacing: 2) {
                    Rectangle().fill(.white).frame(width: 1.5, height: 4)
                    Rectangle().fill(.white).frame(width: 1.5, height: 2)
                    Rectangle().fill(.white).frame(width: 1.5, height: 5)
                }.cornerRadius(0.5)
            }
        }.shadow(color: .white.opacity(0.2), radius: 3)
    }
}

// MARK: - LiquidTabIcon
struct LiquidTabIcon: View {
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
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(width: 76, height: 50)
                        .overlay(
                            Capsule()
                                .fill(.ultraThinMaterial.opacity(0.4))
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.25), lineWidth: 0.3)
                        )
                }
                
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 16 : 18, weight: isSelected ? .semibold : .regular))
                    Text(label)
                        .font(.system(size: isSelected ? 10 : 9, weight: isSelected ? .medium : .regular))
                }
                .foregroundColor(isSelected ? .white : .white.opacity(0.45))
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.interpolatingSpring(stiffness: 500, damping: 10), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}