import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var currentIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if vm.isLoading {
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Hero Banner nhỏ gọn
                            TabView(selection: $currentIndex) {
                                ForEach(Array(vm.trending.prefix(5).enumerated()), id: \.element.id) { i, movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        ZStack(alignment: .bottomLeading) {
                                            AsyncImage(url: movie.backdropURL) { phase in
                                                if let image = phase.image {
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } else {
                                                    Rectangle().fill(Color.gray.opacity(0.08))
                                                }
                                            }
                                            .frame(height: 450)
                                            .clipped()
                                            
                                            LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom)
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(movie.title)
                                                    .font(.title).fontWeight(.heavy).foregroundColor(.white)
                                                HStack {
                                                    Image(systemName: "star.fill").foregroundColor(.white.opacity(0.6)).font(.caption)
                                                    Text(movie.ratingText).foregroundColor(.white).font(.caption)
                                                }
                                            }
                                            .padding()
                                        }
                                    }
                                    .tag(i)
                                }
                            }
                            .tabViewStyle(.page)
                            .frame(height: 450)
                            
                            // Section Xu hướng
                            VStack(alignment: .leading, spacing: 12) {
                                Text("🔥 Xu hướng")
                                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(vm.trending) { movie in
                                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                                VStack(spacing: 6) {
                                                    AsyncImage(url: movie.posterURL) { phase in
                                                        if let image = phase.image {
                                                            image.resizable().aspectRatio(contentMode: .fill)
                                                        } else {
                                                            Rectangle().fill(Color.gray.opacity(0.08))
                                                        }
                                                    }
                                                    .frame(width: 140, height: 210)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    
                                                    Text(movie.title)
                                                        .font(.caption).foregroundColor(.white).lineLimit(1)
                                                        .frame(width: 140)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .task { await vm.loadAll() }
    }
}
