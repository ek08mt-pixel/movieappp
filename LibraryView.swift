import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: LibraryTab = .saved
    
    enum LibraryTab: String, CaseIterable {
        case saved = "Đã lưu"
        case watched = "Từng xem"
    }
    
    var currentMovies: [Movie] {
        selectedTab == .saved ? appState.favorites : appState.watchHistory
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.12), Color(white: 0.05), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    tabBar
                        .padding(.horizontal, 30)
                        .padding(.top, 70)
                    
                    if currentMovies.isEmpty {
                        emptyView
                    } else {
                        movieGrid
                    }
                }
            }
        }
    }
    
    var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(LibraryTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedTab == tab ? .bold : .regular))
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                                ? AnyShapeStyle(Capsule().fill(.ultraThinMaterial.opacity(0.5)))
                                : AnyShapeStyle(Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTab == tab ? Color.white.opacity(0.2) : Color.clear,
                                    lineWidth: 0.5
                                )
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.2))
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        )
    }
    
    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedTab == .saved ? "bookmark.slash" : "eye.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(selectedTab == .saved ? "Chưa có phim đã lưu" : "Chưa có phim đã xem")
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    var movieGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 15),
                    GridItem(.flexible(), spacing: 15),
                    GridItem(.flexible(), spacing: 15)
                ],
                spacing: 15
            ) {
                ForEach(currentMovies) { movie in
                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                        CachedAsyncImage(url: movie.posterURL)
                            .aspectRatio(2/3, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(white: 0.12))
                                    .opacity(movie.posterURL == nil ? 1 : 0)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
}