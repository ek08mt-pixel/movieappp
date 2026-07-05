import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    let categoryPosters: [String: String] = [
        "Marvel": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
        "DC": "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg",
        "Hành động": "/aBw8zYuAljVM1FeK7bRITkfH4g8.jpg",
        "Viễn tưởng": "/ghQrKrcEpAlkzBuNoO7jZAgUx1R.jpg",
        "Kinh dị": "/vJ8cQMNknAY1R4vVxzBSMvQ1W4.jpg",
        "Hài": "/hv7o3VgfsairBoQFAawgaQ4cR1m.jpg"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Tìm phim...", text: $vm.query).focused($focused).foregroundColor(.white)
                            .onChange(of: vm.query) { _ in Task { await vm.search() } }
                        if !vm.query.isEmpty { Button { vm.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) } }
                        if focused { Button("Đóng") { focused = false }.foregroundColor(.white).font(.caption) }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)).padding()
                    
                    if vm.query.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Tìm kiếm phổ biến").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(CategoryConfig.allCategories.prefix(6)) { category in
                                        NavigationLink(destination: CategoryFullView(category: category)) {
                                            ZStack(alignment: .bottom) {
                                                CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(categoryPosters[category.name] ?? "")"))
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                                    .overlay(Color.black.opacity(0.4))
                                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                                Text(category.name)
                                                    .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                                    .padding(.vertical, 4).padding(.horizontal, 10)
                                                    .background(.ultraThinMaterial).clipShape(Capsule()).padding(8)
                                            }
                                        }
                                    }
                                }.padding(.horizontal)
                                
                                Text("Xu hướng").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.horizontal)
                                ForEach(Array(vm.trending.prefix(10).enumerated()), id: \.element.id) { i, movie in
                                    Button { selectedMovie = movie } label: {
                                        HStack(spacing: 12) {
                                            Text("\(i+1)").font(.system(size: 18, weight: .bold)).foregroundColor(.gray).frame(width: 30)
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill).frame(width: 60, height: 90).clipShape(RoundedRectangle(cornerRadius: 8))
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(movie.title).foregroundColor(.white).font(.system(size: 14, weight: .semibold))
                                                HStack { Image(systemName: "star.fill").foregroundColor(.yellow).font(.system(size: 10)); Text(movie.ratingText).foregroundColor(.gray).font(.system(size: 12)) }
                                            }
                                            Spacer()
                                        }.padding(.horizontal)
                                    }
                                }
                            }.padding(.bottom, 100)
                        }
                    } else if vm.results.isEmpty { Spacer(); Text("Không tìm thấy").foregroundColor(.gray); Spacer() }
                    else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(vm.results) { movie in
                                    Button { selectedMovie = movie } label: {
                                        VStack(spacing: 4) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8))
                                            Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                            HStack(spacing: 2) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray) }
                                        }
                                    }
                                }
                            }.padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Tìm kiếm").navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
        }
        .onAppear { focused = true; Task { await vm.loadTrending() } }
    }
}