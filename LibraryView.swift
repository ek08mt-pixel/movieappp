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
                    HStack(spacing: 0) {
                        tabButton(.saved)
                        tabButton(.watched)
                    }
                    .padding(4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                    )
                    .padding(.horizontal, 30)
                    .padding(.top, 70)
                    
                    if currentMovies.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: selectedTab == .saved ? "bookmark.slash" : "eye.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text(selectedTab == .saved ? "Chưa có phim đã lưu" : "Chưa có phim đã xem")
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
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
            }
        }
    }
    
    func tabButton(_ tab: LibraryTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(.ultraThinMaterial.opacity(0.5))
                        } else {
                            Capsule().fill(Color.clear)
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.white.opacity(0.2) : Color.clear, lineWidth: 0.5)
                )
        }
    }
}