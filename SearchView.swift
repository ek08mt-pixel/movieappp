import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    
    let popularTopics: [(String, String, String, Int)] = [
        ("Marvel", "shield.fill", "marvel", 0),
        ("DC", "bolt.fill", "dc comics", 0),
        ("Hành động", "flame.fill", "action", 28),
        ("Viễn tưởng", "rocket.fill", "sci fi", 878),
        ("Kinh dị", "skull.fill", "horror", 27),
        ("Hài", "face.smiling.fill", "comedy", 35),
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
                            Button("Đóng") {
                                focused = false
                            }
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
                                    ForEach(popularTopics, id: \.0) { topic, icon, _, genreId in
                                        NavigationLink(destination: GenreMovieView(genre: Genre(id: genreId, name: topic))) {
                                            VStack(spacing: 8) {
                                                Image(systemName: icon)
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .frame(height: 50)
                                                Text(topic)
                                                    .font(.caption).fontWeight(.medium).foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
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