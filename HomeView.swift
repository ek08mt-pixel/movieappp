import SwiftUI

struct HomeView: View {
    @StateObject var vm = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Xu hướng")
                            .font(.title2).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(vm.trendingMovies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        ZStack(alignment: .bottom) {
                                            AsyncImage(url: movie.posterURL) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Rectangle().fill(Color.gray.opacity(0.1))
                                            }
                                            .frame(width: 140, height: 210)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            Text(movie.title)
                                                .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                                .lineLimit(1)
                                                .padding(8)
                                                .frame(maxWidth: .infinity)
                                                .background(.black.opacity(0.6))
                                        }
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
                                    VStack(alignment: .leading) {
                                        AsyncImage(url: movie.posterURL) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle().fill(Color.gray.opacity(0.1))
                                        }
                                        .frame(height: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Text(movie.title)
                                            .font(.subheadline).foregroundColor(.white).lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            }
        }
        .task {
            await vm.loadMovies()
        }
    }
}
