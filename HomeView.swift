import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if vm.nowPlayingMovies.isEmpty && vm.trendingMovies.isEmpty {
                    ProgressView("Đang tải dữ liệu...")
                        .foregroundColor(.white)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Xu hướng")
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(vm.trendingMovies) { movie in
                                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                                            AsyncImage(url: movie.posterURL) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: { Color.gray.opacity(0.1) }
                                            .frame(width: 140, height: 210)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Text("Đang chiếu rạp")
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                ForEach(vm.nowPlayingMovies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        VStack {
                                            AsyncImage(url: movie.posterURL) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: { Color.gray.opacity(0.1) }
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            Text(movie.title)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top)
                    }
                }
            }
        }
        .task {
            await vm.loadMovies()
        }
    }
}
