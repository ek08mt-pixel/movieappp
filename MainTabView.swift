import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var homeID = UUID()
    @State private var exploreID = UUID()
    @State private var libraryID = UUID()
    @StateObject private var ostManager = OSTManager.shared
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView().id(homeID).opacity(selectedTab == 0 ? 1 : 0)
                ExploreView().id(exploreID).opacity(selectedTab == 1 ? 1 : 0)
                LibraryView().id(libraryID).opacity(selectedTab == 2 ? 1 : 0)
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
                HStack(spacing: 44) {
                    LiquidTabIcon(icon: "house.fill", isSelected: selectedTab == 0) {
                        if selectedTab == 0 { homeID = UUID() } else { selectedTab = 0 }
                    }
                    LiquidTabIcon(icon: "safari.fill", isSelected: selectedTab == 1) {
                        if selectedTab == 1 { exploreID = UUID() } else { selectedTab = 1 }
                    }
                    LiquidTabIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 2) {
                        if selectedTab == 2 { libraryID = UUID() } else { selectedTab = 2 }
                    }
                }
                .padding(.vertical, 14).padding(.horizontal, 32)
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

struct LiquidTabIcon: View {
    let icon: String; let isSelected: Bool; let action: () -> Void
    @State private var isPressed = false
    var body: some View {
        Button {
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 12)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.interpolatingSpring(stiffness: 400, damping: 12)) { isPressed = false } }
            action()
        } label: {
            ZStack {
                if isSelected { Capsule().fill(.ultraThinMaterial.opacity(0.35)).frame(width: 56, height: 38) }
                Image(systemName: icon).font(.system(size: 26, weight: isSelected ? .bold : .regular)).foregroundColor(isSelected ? .white : .white.opacity(0.45)).scaleEffect(isPressed ? 0.8 : 1.0)
            }
        }
    }
}