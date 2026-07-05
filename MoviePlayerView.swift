import SwiftUI
import AVKit

struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showPlayer = false
    @State private var player: AVPlayer?
    
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
                CustomPlayerVC(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
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

// AVPlayerViewController gốc - có sẵn: xoay ngang, PiP, nút Done, controls đẹp
struct CustomPlayerVC: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController()
        c.player = player
        c.showsPlaybackControls = true
        c.videoGravity = .resizeAspect
        c.allowsPictureInPicturePlayback = true
        c.canStartPictureInPictureAutomaticallyFromInline = true
        c.updatesNowPlayingInfoCenter = true
        return c
    }
    
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}