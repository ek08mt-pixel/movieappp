import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Tìm phim, diễn viên...", text: $vm.query)
                            .focused($focused).foregroundColor(.white)
                            .onSubmit { Task { await vm.search() } }
                        if !vm.query.isEmpty {
                            Button { vm.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                    .padding()
                    
                    if vm.results.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass").font(.system(size: 50)).foregroundColor(.gray.opacity(0.5))
                            Text(vm.query.isEmpty ? "Tìm phim yêu thích của bạn" : "Không tìm thấy").foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(vm.results) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        HStack(spacing: 12) {
                                            AsyncImage(url: movie.posterURL) { phase in
                                                if let image = phase.image {
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } else {
                                                    Rectangle().fill(Color.gray.opacity(0.1))
                                                }
                                            }
                                            .frame(width: 80, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(movie.title).foregroundColor(.white).font(.headline).lineLimit(2)
                                                HStack {
                                                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                                    Text(movie.ratingText).foregroundColor(.gray).font(.caption)
                                                    Text("•").foregroundColor(.gray)
                                                    Text(movie.yearText).foregroundColor(.gray).font(.caption)
                                                }
                                                Text(movie.overview).foregroundColor(.gray).font(.caption).lineLimit(2)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal).padding(.vertical, 6)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {}
                }
            }
        }
        .onAppear { focused = true }
    }
}
