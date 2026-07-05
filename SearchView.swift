import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    let topics: [(String, String, String)] = [
        ("Marvel", "marvel", "/or06FN3Dka5tukK1e9sl16pB3iy.jpg"),
        ("DC", "dc", "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg"),
        ("Hành động", "action", "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg"),
        ("Viễn tưởng", "sci fi", "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg"),
        ("Kinh dị", "horror", "/n6bUvigpBOqisP4apFP3FbhqEfA.jpg"),
        ("Hài", "comedy", "/suaEOtk1N1s2XfRk6Fv4QvV7Kq.jpg"),
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
                                Text("Tìm kiếm phổ biến").font(.headline).foregroundColor(.white).padding(.horizontal)
                                
                                CategoryGridView(topics: topics) { query in
                                    vm.query = query
                                    Task { await vm.search() }
                                }
                                
                                Text("Xu hướng").font(.headline).foregroundColor(.white).padding(.horizontal)
                                
                                ForEach(Array(vm.trending.prefix(10).enumerated()), id: \.element.id) { i, movie in
                                    Button { selectedMovie = movie } label: {
                                        HStack(spacing: 12) {
                                            Text("\(i+1)").font(.title3).fontWeight(.bold).foregroundColor(.gray).frame(width: 30)
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill)
                                                .frame(width: 60, height: 90).clipShape(RoundedRectangle(cornerRadius: 8))
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(movie.title).foregroundColor(.white).font(.subheadline).fontWeight(.semibold)
                                                HStack {
                                                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2)
                                                    Text(movie.ratingText).foregroundColor(.gray).font(.caption2)
                                                }
                                            }
                                            Spacer()
                                        }.padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    } else if vm.results.isEmpty {
                        Spacer(); Text("Không tìm thấy").foregroundColor(.gray); Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(vm.results) { movie in
                                    Button { selectedMovie = movie } label: {
                                        VStack(spacing: 4) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            Text(movie.title).font(.system(size: 9)).foregroundColor(.white).lineLimit(2)
                                            HStack(spacing: 2) {
                                                Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                                Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                            }
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

// MARK: - Category Grid (Độc lập, không phụ thuộc biến ngoài)
struct CategoryGridView: View {
    let topics: [(String, String, String)]
    let onSelect: (String) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(topics, id: \.0) { topic, query, poster in
                CategoryCardView(
                    title: topic,
                    posterPath: poster,
                    action: { onSelect(query) }
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Category Card (Độc lập, tự chứa style)
struct CategoryCardView: View {
    let title: String
    let posterPath: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)"))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .blur(radius: 2)
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(6)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
}