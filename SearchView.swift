import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    let popularTopics: [(String, String, String, Int)] = [
        ("Marvel", "marvel", "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", 0),
        ("DC", "dc comics", "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg", 0),
        ("Hành động", "action", "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg", 28),
        ("Viễn tưởng", "sci fi", "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg", 878),
        ("Kinh dị", "horror", "/n6bUvigpBOqisP4apFP3FbhqEfA.jpg", 27),
        ("Hài", "comedy", "/suaEOtk1N1s2XfRk6Fv4QvV7Kq.jpg", 35),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
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
                        if focused {
                            Button("Đóng") { focused = false }
                                .foregroundColor(.orange).font(.caption)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                    .padding()
                    
                    if vm.query.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Tìm kiếm phổ biến")
                                    .font(.headline).foregroundColor(.white).padding(.horizontal)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(popularTopics, id: \.0) { topic, query, poster, genreId in
                                        Button {
                                            vm.query = query
                                            Task { await vm.search() }
                                        } label: {
                                            ZStack(alignment: .bottom) {
                                                CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(poster)"))
                                                    .frame(height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .blur(radius: 3)
                                                    .overlay(Color.black.opacity(0.3))
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                
                                                Text(topic)
                                                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                                    .padding(4).background(Color.black.opacity(0.5))
                                                    .clipShape(Capsule()).padding(4)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                Text("Xu hướng")
                                    .font(.headline).foregroundColor(.white).padding(.horizontal)
                                
                                ForEach(Array(vm.trending.prefix(10).enumerated()), id: \.element.id) { index, movie in
                                    Button { selectedMovie = movie } label: {
                                        HStack(spacing: 12) {
                                            Text("\(index + 1)")
                                                .font(.title3).fontWeight(.bold).foregroundColor(.gray).frame(width: 30)
                                            CachedAsyncImage(url: movie.posterURL)
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
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(vm.results) { movie in
                                    Button { selectedMovie = movie } label: {
                                        VStack(spacing: 4) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 10))
                                            Text(movie.title)
                                                .font(.system(size: 9)).foregroundColor(.white).lineLimit(2)
                                            HStack(spacing: 2) {
                                                Image(systemName: "star.fill").foregroundColor(.yellow).font(.system(size: 7))
                                                Text(movie.ratingText).foregroundColor(.gray).font(.system(size: 8))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
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