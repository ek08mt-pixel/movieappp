import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
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
                        if focused { Button("Đóng") { focused = false }.foregroundColor(.orange).font(.caption) }
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
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(.ultraThinMaterial)
                                                    .frame(height: 95)
                                                    .overlay(
                                                        Image(systemName: iconFor(category.name))
                                                            .font(.system(size: 28)).foregroundColor(.white.opacity(0.3))
                                                    )
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
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(vm.results) { movie in
                                    Button { selectedMovie = movie } label: { MovieGridCard(movie: movie) }
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
    
    func iconFor(_ name: String) -> String {
        switch name {
        case "Marvel": return "shield.fill"
        case "DC": return "bolt.fill"
        case "Hành động": return "flame.fill"
        case "Viễn tưởng": return "rocket.fill"
        case "Kinh dị": return "skull.fill"
        case "Hài": return "face.smiling.fill"
        default: return "film.fill"
        }
    }
}