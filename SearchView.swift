import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    let popularTopics = [
        ("Marvel", "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", "marvel"),
        ("DC", "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg", "dc comics"),
        ("Action", "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg", "action"),
        ("Sci-Fi", "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg", "sci fi"),
        ("Drama", "/zfbjgQE1uSd9wiPTX4VzsLi0rGG.jpg", "drama"),
        ("Comedy", "/suaEOtk1N1s2XfRk6Fv4QvV7Kq.jpg", "comedy")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Tìm phim...", text: $vm.query)
                            .focused($focused).foregroundColor(.white)
                            .onChange(of: vm.query) { _ in Task { await vm.search() } }
                        if !vm.query.isEmpty {
                            Button { vm.query = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                    .padding()
                    
                    if vm.query.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Popular Searches
                                Text("Tìm kiếm phổ biến")
                                    .font(.headline).foregroundColor(.white).padding(.horizontal)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(popularTopics, id: \.0) { topic, poster, query in
                                        Button {
                                            vm.query = query
                                            Task { await vm.search() }
                                        } label: {
                                            ZStack(alignment: .bottom) {
                                                CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(poster)"))
                                                    .frame(height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                
                                                Text(topic)
                                                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                                    .padding(4).background(Color.black.opacity(0.6))
                                                    .clipShape(Capsule()).padding(4)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Trending
                                Text("Xu hướng")
                                    .font(.headline).foregroundColor(.white).padding(.horizontal)
                                
                                ForEach(Array(vm.trending.prefix(10).enumerated()), id: \.element.id) { index, movie in
                                    Button { selectedMovie = movie } label: {
                                        HStack(spacing: 12) {
                                            Text("\(index + 1)")
                                                .font(.title3).fontWeight(.bold).foregroundColor(.gray)
                                                .frame(width: 30)
                                            
                                            CachedAsyncImage(url: movie.posterURL)
                                                .frame(width: 60, height: 90)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
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
                        Spacer()
                        Text("Không tìm thấy").foregroundColor(.gray)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(vm.results) { movie in
                                    Button { selectedMovie = movie } label: {
                                        HStack(spacing: 12) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .frame(width: 70, height: 105)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(movie.title).foregroundColor(.white).font(.subheadline).fontWeight(.semibold).lineLimit(2)
                                                HStack {
                                                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2)
                                                    Text(movie.ratingText).foregroundColor(.gray).font(.caption2)
                                                    Text("•").foregroundColor(.gray)
                                                    Text(movie.yearText).foregroundColor(.gray).font(.caption2)
                                                }
                                            }
                                            Spacer()
                                        }.padding(.horizontal).padding(.vertical, 6)
                                    }
                                    Divider().background(Color.gray.opacity(0.2)).padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tìm kiếm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { dismiss() } }
            }
            .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
        }
        .onAppear {
            focused = true
            Task { await vm.loadTrending() }
        }
    }
}
