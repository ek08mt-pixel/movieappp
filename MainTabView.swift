import SwiftUI
import WebKit

// MARK: - MainTabView
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
            
            // Dynamic Island Mini Player
            if ostManager.isPlaying {
                VStack {
                    MiniPlayerView()
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: ostManager.isPlaying)
            }
            
            // Tab Bar
            HStack(spacing: 12) {
                HStack(spacing: 44) {
                    LiquidTabIcon(icon: "house.fill", isSelected: selectedTab == 0) {
                        if selectedTab == 0 { homeID = UUID() }
                        else { selectedTab = 0 }
                    }
                    LiquidTabIcon(icon: "safari.fill", isSelected: selectedTab == 1) {
                        if selectedTab == 1 { exploreID = UUID() }
                        else { selectedTab = 1 }
                    }
                    LiquidTabIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 2) {
                        if selectedTab == 2 { libraryID = UUID() }
                        else { selectedTab = 2 }
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
            }
            .padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showSearch) { SearchView() }
    }
}

// MARK: - Mini Player (Dynamic Island style)
struct MiniPlayerView: View {
    @StateObject private var ostManager = OSTManager.shared
    @State private var isExpanded = false
    @State private var showYouTube = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showYouTube.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    // Poster nhỏ xíu
                    if let posterPath = ostManager.currentPoster, let url = URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)") {
                        CachedAsyncImage(url: url)
                            .aspectRatio(2/3, contentMode: .fill)
                            .frame(width: 32, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.ultraThinMaterial.opacity(0.5))
                            .frame(width: 32, height: 48)
                            .overlay(Image(systemName: "music.note").font(.system(size: 12)).foregroundColor(.white.opacity(0.6)))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ostManager.currentTrack)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(ostManager.currentMovie)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Play/Pause
                    Button {
                        ostManager.togglePlayback?()
                    } label: {
                        Image(systemName: ostManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                    }
                    
                    // Close
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            ostManager.stopPlayback?()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(width: showYouTube ? UIScreen.main.bounds.width - 32 : 280, height: showYouTube ? 200 : 60)
                .background(
                    RoundedRectangle(cornerRadius: showYouTube ? 20 : 30)
                        .fill(.black.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: showYouTube ? 20 : 30)
                                .fill(.ultraThinMaterial.opacity(0.2))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: showYouTube ? 20 : 30)
                        .stroke(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05), .clear, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            
            // YouTube WebView khi expand
            if showYouTube, let youtubeID = ostManager.currentYoutubeID {
                YouTubeMiniWebView(youtubeID: youtubeID)
                    .frame(width: UIScreen.main.bounds.width - 48, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 6)
            }
        }
    }
}

// MARK: - YouTube Mini WebView
struct YouTubeMiniWebView: UIViewRepresentable {
    let youtubeID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.backgroundColor = .black
        wv.isOpaque = false
        wv.scrollView.isScrollEnabled = false
        let html = """
        <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>body{margin:0;background:black;}</style></head>
        <body><div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>var player;function onYouTubeIframeAPIReady(){player=new YT.Player('player',{videoId:'\(youtubeID)',width:'100%',height:'100%',playerVars:{autoplay:1,controls:0,modestbranding:1,playsinline:1},events:{onReady:function(e){e.target.playVideo()}}})}</script>
        </body></html>
        """
        wv.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        return wv
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Liquid Tab Icon
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