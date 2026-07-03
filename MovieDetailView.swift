import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @StateObject private var vm = MovieDetailViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        AsyncImage(url: movie.backdropURL) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Rectangle().fill(Color.gray.opacity(0.1))
                            }
                        }
                        .frame(height: 250).clipped()
                        LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom).frame(height: 250)
                    }
                    
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            AsyncImage(url: movie.posterURL) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Rectangle().fill(Color.gray.opacity(0.1))
                                }
                            }
                            .frame(width: 95, height: 142)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(movie.title)
                                    .font(.title3).fontWeight(.heavy).foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill").foregroundColor(.white.opacity(0.5)).font(.caption)
                                    Text(movie.ratingText).foregroundColor(.white).font(.subheadline).bold()
                                    Text("•").foregroundColor(.gray)
                                    Text(movie.yearText).foregroundColor(.gray).font(.subheadline)
                                }
                                
                                if !movie.overview.isEmpty {
                                    Text(movie.overview)
                                        .font(.caption).foregroundColor(.gray)
                                        .lineLimit(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        
                        // Buttons
                        HStack(spacing: 10) {
                            if let key = vm.trailerKey {
                                Link(destination: URL(string: "https://youtube.com/watch?v=\(key)")!) {
                                    Label("Trailer", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity).padding(10)
                                        .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                        .font(.caption).fontWeight(.bold)
                                }
                            }
                            
                            Link(destination: URL(string: "https://www.google.com/search?q=đặt+vé+xem+\(movie.title.replacingOccurrences(of: " ", with: "+"))")!) {
                                Label("Đặt vé", systemImage: "ticket.fill")
                                    .frame(maxWidth: .infinity).padding(10)
                                    .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                    .font(.caption).fontWeight(.bold)
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
                                    .frame(maxWidth: .infinity).padding(10)
                                    .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                    .font(.caption).fontWeight(.semibold)
                            }
                        }
                        
                        // Cast
                        if !vm.actors.isEmpty {
                            Text("Diễn viên").font(.headline).fontWeight(.bold).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(vm.actors.prefix(12)) { actor in
                                        NavigationLink(destination: ActorDetailView(actor: actor)) {
                                            VStack(spacing: 4) {
                                                AsyncImage(url: actor.profileURL) { phase in
                                                    if let image = phase.image {
                                                        image.resizable().aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Circle().fill(Color.gray.opacity(0.1))
                                                    }
                                                }
                                                .frame(width: 60, height: 60).clipShape(Circle())
                                                Text(actor.name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 60)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Similar
                        if !vm.similar.isEmpty {
                            Text("Phim tương tự").font(.headline).fontWeight(.bold).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.similar) { m in
                                        NavigationLink(destination: MovieDetailView(movie: m)) {
                                            VStack(spacing: 5) {
                                                AsyncImage(url: m.posterURL) { phase in
                                                    if let image = phase.image {
                                                        image.resizable().aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Rectangle().fill(Color.gray.opacity(0.08))
                                                    }
                                                }
                                                .frame(width: 120, height: 180)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                Text(m.title).font(.system(size: 11)).foregroundColor(.white).lineLimit(1).frame(width: 120)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer().frame(height: 120)
                }
            }
        }
        .task { await vm.load(movieId: movie.id) }
    }
}
