import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    // Callback khi chọn phim - dùng cho Watch Together
    var onSelectMovie: ((Movie) -> Void)?
    
    private let columns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Tìm phim...", text: $vm.query).focused($focused).foregroundColor(.white)
                            .onChange(of: vm.query) { _ in Task { await vm.search() } }
                        if !vm.query.isEmpty { Button { vm.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) } }
                        if focused { Button("Đóng") { focused = false }.foregroundColor(.white).font(.caption) }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)).padding(.horizontal).padding(.top, 54)
                    
                    if vm.query.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Tìm phim, TV show...")
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    } else if vm.results.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "movieclapper")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Không tìm thấy")
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(vm.results) { movie in
                                    Button {
                                        if let callback = onSelectMovie {
                                            callback(movie)
                                            dismiss()
                                        } else {
                                            selectedMovie = movie
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8))
                                                .shadow(color: .black.opacity(0.3), radius: 3)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color(white: 0.12))
                                                        .opacity(movie.posterURL == nil ? 1 : 0)
                                                )
                                            Text(movie.title)
                                                .font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                            HStack(spacing: 2) {
                                                Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                                Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                            }.padding(.horizontal, 16).padding(.bottom, 100)
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
        }
        .onAppear { focused = true; Task { await vm.loadTrending() } }
    }
}