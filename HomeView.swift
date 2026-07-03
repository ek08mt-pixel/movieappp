import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Xu hướng").font(.title2).bold().foregroundColor(.white).padding()
                    
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(vm.trendingMovies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    AsyncImage(url: movie.posterURL).frame(width: 140, height: 210).clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    
                    Text("Đang chiếu rạp").font(.title2).bold().foregroundColor(.white).padding()
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(vm.nowPlayingMovies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack {
                                    AsyncImage(url: movie.posterURL).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(movie.title).foregroundColor(.white).lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.black)
            .task { await vm.loadMovies() }
        }
    }
}
