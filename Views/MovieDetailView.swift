import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @StateObject private var vm = MovieDetailViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Backdrop
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: movie.backdropURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(height: 250)
                        .clipped()
                        
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .frame(height: 250)
                        
                        HStack(alignment: .bottom, spacing: 16) {
                            AsyncImage(url: movie.posterURL) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 100, height: 150)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.5), radius: 8)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(movie.title)
                                    .font(.title2).fontWeight(.heavy).foregroundColor(.white)
                                
                                HStack(spacing: 8) {
                                    Label(movie.ratingText, systemImage: "star.fill")
                                        .foregroundColor(.yellow).font(.subheadline)
                                    Text(movie.yearText).foregroundColor(.gray)
                                    Text("•").foregroundColor(.gray)
                                    Text(movie.voteCountFormatted + " votes").foregroundColor(.gray).font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .offset(y: 40)
                    }
                    
                    // Actions
                    HStack(spacing: 16) {
                        // Trailer
                        if let trailer = vm.trailerKey {
                            Link(destination: URL(string: "https://youtube.com/watch?v=\(trailer)")!) {
                                Label("Xem Trailer", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity).padding().background(Color.orange).cornerRadius(12)
                                    .foregroundColor(.black).bold()
                            }
                        }
                        
                        // Book ticket
                        Link(destination: URL(string: "https://www.google.com/search?q=đặt+vé+\(movie.title.replacingOccurrences(of: " ", with: "+"))")!) {
                            Label("Đặt vé", systemImage: "ticket.fill")
                                .frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.15)).cornerRadius(12)
                                .foregroundColor(.white).bold()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    // Favorite button
                    Button {
                        if appState.favorites.contains(where: { $0.id == movie.id }) {
                            appState.favorites.removeAll { $0.id == movie.id }
                        } else {
                            appState.favorites.append(movie)
                        }
                    } label: {
                        Label(
                            appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã yêu thích" : "Thêm yêu thích",
                            systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "heart.fill" : "heart"
                        )
                        .foregroundColor(appState.favorites.contains(where: { $0.id == movie.id }) ? .red : .gray)
                    }
                    .padding(.horizontal).padding(.top, 16)
                    
                    // Overview
                    Text("Tổng quan")
                        .font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.horizontal).padding(.top, 20)
                    
                    Text(movie.overview.isEmpty ? "Chưa có mô tả." : movie.overview)
                        .foregroundColor(.gray).padding(.horizontal).padding(.top, 4)
                    
                    // Cast
                    if !vm.actors.isEmpty {
                        Text("Diễn viên")
                            .font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.horizontal).padding(.top, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(vm.actors) { actor in
                                    NavigationLink(destination: ActorDetailView(actor: actor)) {
                                        VStack(spacing: 6) {
                                            AsyncImage(url: actor.profileURL) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Circle().fill(Color.gray.opacity(0.3))
                                            }
                                            .frame(width: 70, height: 70)
                                            .clipShape(Circle())
                                            
                                            Text(actor.name)
                                                .font(.caption2).foregroundColor(.white).lineLimit(1)
                                                .frame(width: 70)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Similar
                    if !vm.similar.isEmpty {
                        MovieSection(title: "Phim tương tự", movies: vm.similar, style: .poster)
                    }
                    
                    Spacer().frame(height: 120)
                }
            }
        }
        .task {
            await vm.load(movieId: movie.id)
            appState.watchHistory.append(movie)
        }
    }
}
