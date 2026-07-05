import SwiftUI
import AVKit

struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var player: AVPlayer?
    @State private var errorMessage: String?
    @State private var showControls = true
    @State private var isPlaying = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Đợi Mew tí...").foregroundColor(.white.opacity(0.7)).font(.headline)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash").font(.system(size: 50)).foregroundColor(.gray)
                    Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                    Button("Thử lại") { loadStream() }.foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                }
            } else if let player = player {
                // Video full màn hình
                VideoPlayerView(player: player)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { showControls.toggle() } }
                
                // Overlay Netflix-style
                if showControls {
                    VStack {
                        // Top bar
                        HStack {
                            Button {
                                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                            Spacer()
                            Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 20).padding(.top, 50)
                        
                        Spacer()
                        
                        // Bottom controls
                        HStack(spacing: 32) {
                            Button {
                                let t = CMTime(seconds: max(player.currentTime().seconds - 10, 0), preferredTimescale: 600)
                                player.seek(to: t)
                            } label: {
                                Image(systemName: "gobackward.10").font(.system(size: 24)).foregroundColor(.white)
                            }
                            
                            Button {
                                if isPlaying { player.pause() } else { player.play() }
                                isPlaying.toggle()
                            } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 40)).foregroundColor(.white)
                            }
                            
                            Button {
                                let t = CMTime(seconds: player.currentTime().seconds + 10, preferredTimescale: 600)
                                player.seek(to: t)
                            } label: {
                                Image(systemName: "goforward.10").font(.system(size: 24)).foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // PiP
                            Button {
                                if let pipVC = (player.currentItem?.asset as? AVURLAsset)?.url {
                                    // PiP tự động từ AVPlayerViewController
                                }
                            } label: {
                                Image(systemName: "pip.enter")
                                    .font(.system(size: 20)).foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 32).padding(.bottom, 40)
                        .background(LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom))
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
        .onDisappear {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        .task { loadStream() }
    }
    
    func loadStream() {
        isLoading = true; errorMessage = nil; player = nil
        Task {
            do {
                let imdbId = try await fetchIMDbId()
                let url = try await fetchNTL(imdbId)
                await MainActor.run {
                    let p = AVPlayer(url: url)
                    p.allowsExternalPlayback = true
                    self.player = p
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false }
            }
        }
    }
    
    func fetchNTL(_ id: String) async throws -> URL {
        var r = URLRequest(url: URL(string: "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(id).json")!)
        r.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (d, _) = try await URLSession.shared.data(for: r)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String? }
        let res = try JSONDecoder().decode(R.self, from: d)
        guard let u = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url, let vu = URL(string: u) else { throw NSError(domain: "", code: -1) }
        return vu
    }
    
    func fetchIMDbId() async throws -> String {
        let (d, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
        struct E: Codable { let imdb_id: String? }
        guard let id = try JSONDecoder().decode(E.self, from: d).imdb_id else { throw NSError(domain: "", code: -1) }
        return id
    }
}

// Video Player UIView - full màn hình, không khung đen
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

class PlayerUIView: UIView {
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}