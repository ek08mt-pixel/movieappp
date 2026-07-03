import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if vm.isLoading {
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("🔥 Xu hướng")
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(vm.trending) { movie in
                                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                                            VStack {
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
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 40)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .task { await vm.loadAll() }
    }
}
