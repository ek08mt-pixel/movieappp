import SwiftUI

// MARK: - MainTabView
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var homeID = UUID()
    @State private var exploreID = UUID()
    @State private var watchTogetherID = UUID()
    @State private var libraryID = UUID()
    @State private var showWatchTogetherRoom = false
    @StateObject private var ostManager = OSTManager.shared
    @StateObject private var watchService = WatchTogetherService.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .id(homeID)
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)
                
                ExploreView()
                    .id(exploreID)
                    .tabItem { Label("Explore", systemImage: "safari.fill") }
                    .tag(1)
                
                WatchTogetherRoomView()
                    .id(watchTogetherID)
                    .tabItem { Label("Watch", systemImage: "person.3.fill") }
                    .tag(2)
                
                LibraryView()
                    .id(libraryID)
                    .tabItem { Label("Library", systemImage: "rectangle.stack.fill") }
                    .tag(3)
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewBottomAccessory {
                HStack {
                    // MiniPlayer bên trái nếu đang phát OST
                    if ostManager.isPlaying {
                        miniPlayerCompact
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Button Search bên phải
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                    }
                    .sheet(isPresented: .constant(false)) {
                        SearchView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onSubmit(of: .search) {
                // Mở SearchView với query
            }
            .onChange(of: selectedTab) { tab in
                if tab == 0 { homeID = UUID() }
                else if tab == 1 { exploreID = UUID() }
                else if tab == 2 { watchTogetherID = UUID() }
                else if tab == 3 { libraryID = UUID() }
            }
        }
        .animation(.spring(response: 0.4), value: showWatchTogetherRoom)
        .fullScreenCover(isPresented: $ostManager.showOSTView) { OSTView() }
        .onChange(of: watchService.isInRoom) { inRoom in
            withAnimation { showWatchTogetherRoom = inRoom }
        }
    }
    
    // MiniPlayer compact cho tabViewBottomAccessory
    var miniPlayerCompact: some View {
        Button {
            ostManager.showOSTView = true
        } label: {
            HStack(spacing: 6) {
                if let poster = ostManager.currentPoster, let url = URL(string: "https://image.tmdb.org/t/p/w200\(poster)") {
                    CachedAsyncImage(url: url)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .frame(width: 24, height: 36)
                        .overlay(Image(systemName: "music.note").font(.system(size: 8)).foregroundColor(.white.opacity(0.6)))
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(ostManager.currentTrack)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(ostManager.currentMovie)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                .frame(width: 80, alignment: .leading)
                
                Button {
                    ostManager.togglePlayback?()
                } label: {
                    Image(systemName: ostManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                }
                
                Button {
                    withAnimation { ostManager.stopPlayback?() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(.ultraThinMaterial.opacity(0.2)))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.9)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}