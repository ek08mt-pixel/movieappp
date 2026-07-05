import SwiftUI
import AVKit

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var player: AVPlayer?
    @State private var errorMessage: String?
    @State private var selectedSource = 0
    @State private var showOverlay = true
    @State private var isPlaying = true
    
    let sources = ["NTL Stream", "VidLink", "MultiEmbed"]
    
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
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                    Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding()
                    Button("Thử lại") { loadStream() }.foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                    ForEach(0..<sources.count, id: \.self) { i in
                        Button(sources[i]) { selectedSource = i; loadStream() }
                            .foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(.white.opacity(0.15))).font(.caption2)
                    }
                }
            } else if let player = player {
                ZStack {
                    // AVPlayerLayer trực tiếp - không khung đen
                    VideoPlayerView(player: player)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { showOverlay.toggle() } }
                    
                    // Overlay Netflix-style
                    if showOverlay {
                        VStack {
                            // Top bar - Nút Back
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
                            }
                            .padding(.horizontal, 20).padding(.top, 50)
                            
                            Spacer()
                            
                            // Bottom controls
                            HStack(spacing: 24) {
                                // Play/Pause
                                Button {
                                    if isPlaying { player.pause() } else { player.play() }
                                    isPlaying.toggle()
                                } label: {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 28)).foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                // Tua lại 10s
                                Button {
                                    let newTime = CMTime(seconds: max(player.currentTime().seconds - 10, 0), preferredTimescale: 600)
                                    player.seek(to: newTime)
                                } label: {
                                    Image(systemName: "gobackward.10")
                                        .font(.system(size: 22)).foregroundColor(.white)
                                }
                                
                                // Tua tới 10s
                                Button {
                                    let newTime = CMTime(seconds: player.currentTime().seconds + 10, preferredTimescale: 600)
                                    player.seek(to: newTime)
                                } label: {
                                    Image(systemName: "goforward.10")
                                        .font(.system(size: 22)).foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                // Chọn nguồn
                                Menu {
                                    ForEach(0..<sources.count, id: \.self) { i in
                                        Button(sources[i]) { selectedSource = i; loadStream() }
                                    }
                                } label: {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 20)).foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 32).padding(.bottom, 40)
                            .background(
                                LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                            )
                        }
                        .transition(.opacity)
                    }
                }
                .onAppear {
                    player.play()
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                }
                .onDisappear {
                    player.pause()
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                }
            }
        }
        .task { loadStream() }
    }
    
    func loadStream() {
        isLoading = true; errorMessage = nil; player = nil
        Task {
            do {
                let imdbId = try await fetchIMDbId()
                let url = try await fetchNTL(imdbId)
                await MainActor.run { self.player = AVPlayer(url: url); self.isLoading = false }
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

// MARK: - VideoPlayerView (AVPlayerLayer - không khung đen)
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
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}