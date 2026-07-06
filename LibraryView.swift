import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.12), Color(white: 0.05), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if appState.favorites.isEmpty {
                VStack(spacing: 12) { Image(systemName: "bookmark.slash").font(.system(size: 50)).foregroundColor(.gray); Text("Chưa có phim đã lưu").foregroundColor(.gray) }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)], spacing: 15) {
                        ForEach(appState.favorites) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.12)).opacity(movie.posterURL == nil ? 1 : 0))
                            }
                        }
                    }.padding(.horizontal, 16).padding(.top, 90).padding(.bottom, 100)
                }
            }
        }
    }
}