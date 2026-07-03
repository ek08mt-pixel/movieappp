import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @StateObject private var vm = MovieDetailViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                ZStack(alignment: .bottom) {
                    AsyncImage(url: movie.backdropURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.gray.opacity(0.15))
                        }
                    }
                    .frame(height: 300)
                    .clipped()
                    
                    LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom)
                        .frame(height: 300)
                    
                    HStack(alignment: .bottom, spacing: 16) {
                        AsyncImage(url: movie.posterURL) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Rectangle().fill(Color.gray.opacity(0.2))
                            }
                        }
                        .frame(width: 110, height: 165)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.5), radius: 8)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(movie.title)
                                .font(.title2).fontWeight(.heavy).foregroundColor(.white)
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                Text(movie.ratingText).foregroundColor(.white).font(.subheadline).bold()
                                Text("•").foregroundColor(.gray)
                                Text(movie.yearText).foregroundColor(.gray)
                                Text("•").foregroundColor(.gray)
                                Text(movie.voteCountFormatted).foregroundColor(.gray).font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .offset(y: 40)
                }
                
                VStack(spacing: 20) {
                    // Nút hành động
                    HStack(spacing: 12) {
                        if let key = vm.trailerKey {
                            Link(destination: URL(string: "https://youtube.com/watch?v=\(key)")!) {
                                Label("Trailer", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity).padding(12)
                                    .background(Color.orange).foregroundColor(.black).clipShape(Capsule()).fontWeight(.bold)
                            }
                        }
                        
                        Button {
                            if appState.favorites.contains(where: {$0.id == movie.id}) {
                                appState.favorites.removeAll {$0.id == movie.id}
                            } else {
                                appState.favorites.append(movie)
                            }
                        } label: {
                            Label(appState.favorites.contains(where: {$0.id == movie.id}) ? "Đã lưu" : "Lưu",
                                  systemImage: appState.favorites.contains(where: {$0.id == movie.id}) ? "checkmark" : "plus")
                                .frame(maxWidth: .infinity).padding(12)
                                .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule()).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    // Mô tả
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nội dung").font(.title3).fontWeight(.bold).foregroundColor(.white)
                        Text(movie.overview).foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Diễn viên
                    if !vm.actors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Diễn viên").font(.title3).fontWeight(.bold).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(vm.actors.prefix(12)) { actor in
                                        NavigationLink(destination: ActorDetailView(actor: actor)) {
                                            VStack(spacing: 6) {
                                                AsyncImage(url: actor.profileURL) { phase in
                                                    if let image = phase.image {
                                                        image.resizable().aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Circle().fill(Color.gray.opacity(0.2))
                                                    }
                                                }
                                                .frame(width: 64, height: 64)
                                                .clipShape(Circle())
                                                
                                                Text(actor.name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 64)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Phim tương tự
                    if !vm.similar.isEmpty {
                        PosterSection(title: "Phim tương tự", movies: vm.similar)
                    }
                    
                    Spacer().frame(height: 120)
                }
            }
        }
        .task { await vm.load(movieId: movie.id) }
    }
}
