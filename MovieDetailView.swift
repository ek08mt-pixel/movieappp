import SwiftUI
import WebKit

struct MovieDetailView: View {
    let movie: Movie
    var showBooking: Bool = false
    @StateObject private var vm = MovieDetailViewModel()
    @StateObject private var colorManager = DynamicColorManager()
    @EnvironmentObject var appState: AppState
    @State private var showTrailer = false
    @State private var showBookingSheet = false
    @State private var showFullOverview = false
    @State private var commentText = ""
    @State private var comments: [String] = []
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [colorManager.dominantColor, colorManager.secondaryColor, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        CachedAsyncImage(url: movie.backdropURL)
                            .frame(height: 250).clipped()
                        LinearGradient(colors: [.clear, colorManager.secondaryColor], startPoint: .center, endPoint: .bottom).frame(height: 250)
                    }
                    
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            CachedAsyncImage(url: movie.posterURL)
                                .frame(width: 95, height: 142).clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(movie.title).font(.title3).fontWeight(.heavy).foregroundColor(.white)
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                    Text(movie.ratingText).foregroundColor(.white).font(.subheadline).bold()
                                    Text("•").foregroundColor(.gray)
                                    Text(movie.yearText).foregroundColor(.gray)
                                }
                                Button {
                                    showFullOverview = true
                                } label: {
                                    Text(movie.overview).font(.caption).foregroundColor(.gray).lineLimit(4).multilineTextAlignment(.leading)
                                }
                            }
                        }
                        
                        HStack(spacing: 10) {
                            if vm.trailerKey != nil {
                                Button { showTrailer = true } label: {
                                    Label("Trailer", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity).padding(10)
                                        .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                        .font(.caption).fontWeight(.bold)
                                }
                            }
                            
                            if showBooking {
                                Button { showBookingSheet = true } label: {
                                    Label("Đặt vé", systemImage: "ticket.fill")
                                        .frame(maxWidth: .infinity).padding(10)
                                        .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                        .font(.caption).fontWeight(.bold)
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
                                    .frame(maxWidth: .infinity).padding(10)
                                    .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                    .font(.caption).fontWeight(.semibold)
                            }
                        }
                        
                        QuoteView(movieId: movie.id).padding(.vertical, 8)
                        
                        if !vm.actors.isEmpty {
                            Text("Diễn viên").font(.headline).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(vm.actors.prefix(15)) { actor in
                                        NavigationLink(destination: ActorDetailView(actor: actor)) {
                                            VStack(spacing: 4) {
                                                CachedAsyncImage(url: actor.profileURL)
                                                    .frame(width: 60, height: 60).clipShape(Circle())
                                                Text(actor.name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 60)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !vm.similar.isEmpty {
                            Text("Phim tương tự").font(.headline).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHGrid(rows: [GridItem(.fixed(165)), GridItem(.fixed(165))], spacing: 10) {
                                    ForEach(vm.similar.prefix(12)) { m in
                                        NavigationLink(destination: MovieDetailView(movie: m)) {
                                            ZStack(alignment: .bottom) {
                                                CachedAsyncImage(url: m.posterURL)
                                                    .frame(width: 110, height: 165).clipShape(RoundedRectangle(cornerRadius: 12))
                                                VStack(spacing: 2) {
                                                    Text(m.title).font(.system(size: 10)).fontWeight(.semibold).foregroundColor(.white).lineLimit(2)
                                                }
                                                .padding(.horizontal, 6).padding(.vertical, 6).frame(width: 110)
                                                .background(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                            .frame(width: 110, height: 165)
                                        }
                                    }
                                }.padding(.horizontal, 20)
                            }
                        }
                        
                        // Comment section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bình luận").font(.headline).foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                TextField("Viết bình luận...", text: $commentText)
                                    .textFieldStyle(.plain).foregroundColor(.white).padding(10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                                
                                Button {
                                    if !commentText.isEmpty {
                                        comments.append(commentText)
                                        commentText = ""
                                    }
                                } label: {
                                    Text("Gửi").font(.caption).fontWeight(.bold).foregroundColor(.orange)
                                }
                            }
                            
                            ForEach(comments, id: \.self) { comment in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(.ultraThinMaterial).frame(width: 30, height: 30)
                                        .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.6)).font(.system(size: 14)))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Người dùng").font(.caption).fontWeight(.bold).foregroundColor(.white)
                                        Text(comment).font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    Spacer().frame(height: 100)
                }
            }
        }
        .task {
            await vm.load(movieId: movie.id)
            colorManager.extractColors(from: movie.backdropURL)
        }
        .sheet(isPresented: $showFullOverview) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ScrollView {
                        Text(movie.overview)
                            .foregroundColor(.white).padding()
                    }
                }
                .navigationTitle(movie.title)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { showFullOverview = false } } }
            }
        }
        .fullScreenCover(isPresented: $showTrailer) {
            ZStack {
                Color.black.ignoresSafeArea()
                WebView(urlString: "https://www.youtube.com/embed/\(vm.trailerKey ?? "")?autoplay=1").ignoresSafeArea()
            }
            .overlay(alignment: .topLeading) {
                Button { showTrailer = false } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white.opacity(0.8)).padding()
                }
            }
        }
        .sheet(isPresented: $showBookingSheet) {
            NavigationStack {
                WebView(urlString: "https://www.google.com/search?q=đặt+vé+xem+phim+\(movie.title.replacingOccurrences(of: " ", with: "+"))")
                    .ignoresSafeArea()
                    .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { showBookingSheet = false } } }
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
        if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}