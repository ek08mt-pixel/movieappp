import SwiftUI
import AVKit

// MARK: - Rotatable Player VC
class RotatablePlayerVC: AVPlayerViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
    override var shouldAutorotate: Bool { true }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var player: AVPlayer?
    @State private var errorMessage: String?
    @State private var selectedSource = 0
    @State private var showOverlay = true
    @State private var sourceStatus: [Int: Bool] = [:]
    
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
                    HStack(spacing: 12) {
                        Button("Thử lại") { loadStream() }.foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                        ForEach(0..<sources.count, id: \.self) { i in
                            Button(sources[i]) { selectedSource = i; loadStream() }
                                .foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().fill(.white.opacity(0.15))).font(.caption2)
                        }
                    }
                }
            } else if let player = player {
                // Player với overlay SwiftUI
                ZStack {
                    RotatablePlayerView(player: player)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { showOverlay.toggle() } }
                    
                    if showOverlay {
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
                                        .padding(10)
                                        .background(Circle().fill(.ultraThinMaterial))
                                }
                                Spacer()
                                Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                                Spacer()
                                Text(sources[selectedSource]).font(.caption2).foregroundColor(.gray)
                                    .padding(6).background(Capsule().fill(.ultraThinMaterial))
                            }
                            .padding(.horizontal, 16).padding(.top, 50)
                            
                            Spacer()
                            
                            // Bottom controls
                            HStack(spacing: 20) {
                                // Nút chọn nguồn
                                Menu {
                                    ForEach(0..<sources.count, id: \.self) { i in
                                        Button(sources[i]) { selectedSource = i; loadStream() }
                                    }
                                } label: {
                                    Label("Đổi nguồn", systemImage: "list.bullet")
                                        .font(.caption).foregroundColor(.white)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(Capsule().fill(.ultraThinMaterial))
                                }
                                
                                Spacer()
                                
                                // PiP
                                Button {
                                    player.pause()
                                } label: {
                                    Image(systemName: "pause.circle.fill")
                                        .font(.system(size: 36)).foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                // Tua nhanh
                                Button {
                                    player.seek(to: CMTime(seconds: player.currentTime().seconds + 10, preferredTimescale: 600))
                                } label: {
                                    Image(systemName: "goforward.10")
                                        .font(.system(size: 24)).foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 24).padding(.bottom, 40)
                            .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
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

// MARK: - Rotatable Player View
struct RotatablePlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> RotatablePlayerVC {
        let c = RotatablePlayerVC(); c.player = player; c.showsPlaybackControls = false
        c.videoGravity = .resizeAspect; c.allowsPictureInPicturePlayback = true; c.canStartPictureInPictureAutomaticallyFromInline = true; return c
    }
    func updateUIViewController(_ ui: RotatablePlayerVC, context: Context) {}
}