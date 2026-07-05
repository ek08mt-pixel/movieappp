import SwiftUI
import WebKit

struct MovieDetailView: View {
    let movie: Movie; var showBooking: Bool = false
    @StateObject private var vm = MovieDetailViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showTrailer = false
    @State private var showBookingSheet = false
    @State private var showFullOverview = false
    @State private var commentText = ""
    @State private var comments: [String] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Backdrop
                    ZStack(alignment: .topLeading) {
                        CachedAsyncImage(url: movie.backdropURL)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: 320).clipped()
                            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom))
                        
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 30)).foregroundColor(.white).shadow(color: .black.opacity(0.5), radius: 4)
                        }.padding(.top, 54).padding(.leading, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Poster + Info
                        HStack(alignment: .top, spacing: 14) {
                            CachedAsyncImage(url: movie.posterURL)
                                .aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.4), radius: 6).offset(y: -45)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Spacer().frame(height: 8)
                                Text(movie.title).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.subheadline)
                                    Text(movie.ratingText).foregroundColor(.white).font(.subheadline).bold()
                                    Text("•").foregroundColor(.gray); Text(movie.yearText).foregroundColor(.gray)
                                }
                                // Nội dung - bấm vào mở rộng ngay tại chỗ
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(movie.overview.isEmpty ? "Chưa có mô tả." : movie.overview)
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                        .lineLimit(showFullOverview ? nil : 4)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    if movie.overview.count > 200 {
                                        Button(showFullOverview ? "Thu gọn" : "Xem thêm") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showFullOverview.toggle()
                                            }
                                        }
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                        
                        // Nút chức năng
                        HStack(spacing: 10) {
                            if vm.trailerKey != nil {
                                Button { showTrailer = true } label: {
                                    Label("Trailer", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                        .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                                }
                            }
                            NavigationLink(destination: AskAIView(movie: movie)) {
                                Label("Hỏi AI", systemImage: "brain").frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                    .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                            Button {
                                if appState.favorites.contains(where: { $0.id == movie.id }) { appState.favorites.removeAll { $0.id == movie.id } }
                                else { appState.favorites.append(movie) }
                            } label: {
                                Label(appState.favorites.contains(where: { $0.id == movie.id }) ? "Đã lưu" : "Lưu",
                                      systemImage: appState.favorites.contains(where: { $0.id == movie.id }) ? "checkmark" : "plus")
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                    .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                        }
                        
                        if showBooking {
                            Button { showBookingSheet = true } label: {
                                Label("Đặt vé", systemImage: "ticket.fill").frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                                    .clipShape(Capsule()).foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                            }
                        }
                        
                        QuoteView(movieId: movie.id)
                        
                        if !vm.actors.isEmpty {
                            Text("Diễn viên").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(vm.actors.prefix(15)) { actor in
                                        NavigationLink(destination: ActorDetailView(actor: actor)) {
                                            VStack(spacing: 6) {
                                                CachedAsyncImage(url: actor.profileURL).aspectRatio(contentMode: .fill).frame(width: 64, height: 64).clipShape(Circle())
                                                Text(actor.name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 64)
                                            }
                                        }
                                    }
                                }.padding(.horizontal)
                            }
                        }
                        
                        if !vm.similar.isEmpty {
                            Text("Phim tương tự").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(vm.similar.prefix(12)) { m in
                                        NavigationLink(destination: MovieDetailView(movie: m)) {
                                            VStack(spacing: 6) {
                                                CachedAsyncImage(url: m.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(color: .black.opacity(0.3), radius: 4)
                                                Text(m.title).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2).frame(width: 120)
                                            }
                                        }
                                    }
                                }.padding(.horizontal)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bình luận").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            HStack(spacing: 8) {
                                TextField("Viết bình luận...", text: $commentText).textFieldStyle(.plain).foregroundColor(.white).padding(10).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                                Button { if !commentText.isEmpty { comments.append(commentText); commentText = "" } } label: { Text("Gửi").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.7)) }
                            }
                            ForEach(comments, id: \.self) { c in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(.ultraThinMaterial).frame(width: 30, height: 30).overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.6)).font(.system(size: 14)))
                                    VStack(alignment: .leading, spacing: 2) { Text("Người dùng").font(.caption).fontWeight(.bold).foregroundColor(.white); Text(c).font(.caption).foregroundColor(.gray) }
                                    Spacer()
                                }
                            }
                        }.padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    Spacer().frame(height: 100)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .task { await vm.load(movieId: movie.id) }
        .fullScreenCover(isPresented: $showTrailer) {
            ZStack { Color.black.ignoresSafeArea(); WebView(urlString: "https://www.youtube.com/embed/\(vm.trailerKey ?? "")?autoplay=1").ignoresSafeArea() }
                .overlay(alignment: .topLeading) { Button { showTrailer = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white.opacity(0.8)).padding() } }
        }
        .sheet(isPresented: $showBookingSheet) {
            NavigationStack { WebView(urlString: "https://www.google.com/search?q=đặt+vé+xem+phim+\(movie.title.replacingOccurrences(of: " ", with: "+"))").ignoresSafeArea()
                    .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { showBookingSheet = false } } } }
        }
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView { let wv = WKWebView(); wv.backgroundColor = .black; wv.isOpaque = false; if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }; return wv }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}