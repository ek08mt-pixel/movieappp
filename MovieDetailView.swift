import SwiftUI
import WebKit
import AVKit

struct MovieDetailView: View {
    let movie: Movie
    @StateObject private var vm = MovieDetailViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showTrailer = false
    @State private var showBooking = false
    
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
                            // Nút Trailer - mở video ngay trong app
                            if vm.trailerKey != nil {
                                Button {
                                    showTrailer = true
                                } label: {
                                    Label("Trailer", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity).padding(10)
                                        .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                        .font(.caption).fontWeight(.bold)
                                }
                            }
                            
                            // Nút Đặt vé - mở web đặt vé phim
                            Button {
                                showBooking = true
                            } label: {
                                Label("Đặt vé", systemImage: "ticket.fill")
                                    .frame(maxWidth: .infinity).padding(10)
                                    .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                    .font(.caption).fontWeight(.bold)
                            }
                            
                            // Nút Lưu
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
        // Trailer player
        .fullScreenCover(isPresented: $showTrailer) {
            TrailerPlayerView(trailerKey: vm.trailerKey ?? "")
        }
        // Web đặt vé
        .sheet(isPresented: $showBooking) {
            BookingWebView(movieTitle: movie.title)
        }
    }
}

// MARK: - Trailer Player (video ngay trong app)
struct TrailerPlayerView: View {
    let trailerKey: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VideoPlayerView(key: trailerKey)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let key: String
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        if let url = URL(string: "https://www.youtube.com/watch?v=\(key)") {
            // Dùng WebView để nhúng YouTube thay vì AVPlayer
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// MARK: - WebView đặt vé
struct BookingWebView: View {
    let movieTitle: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Mở web đặt vé - dùng Google search "đặt vé xem [tên phim]"
                WebView(urlString: "https://www.google.com/search?q=đặt+vé+xem+phim+\(movieTitle.replacingOccurrences(of: " ", with: "+"))")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.backgroundColor = .black
        wv.isOpaque = false
        if let url = URL(string: urlString) {
            wv.load(URLRequest(url: url))
        }
        return wv
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
