import SwiftUI
import WebKit
import AVKit

// MARK: - MediaFusion Manager
class MediaFusionManager {
    static let shared = MediaFusionManager()
    private let baseURL = "https://mediafusion.elfhosted.com"
    private let session: URLSession = {
        let c = URLSessionConfiguration.default; c.httpCookieAcceptPolicy = .always; return URLSession(configuration: c)
    }()
    
    func getBestURL(imdbId: String) async throws -> URL {
        let cleanId = imdbId.replacingOccurrences(of: "tt", with: "")
        let urlString = "\(baseURL)/stream/movie/\(cleanId).json"
        var req = URLRequest(url: URL(string: urlString)!)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        req.setValue("https://mediafusion.elfhosted.com/", forHTTPHeaderField: "Referer")
        let (data, _) = try await session.data(for: req)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String?; let type: String?; let infoHash: String? }
        let res = try JSONDecoder().decode(R.self, from: data)
        let filtered = res.streams?.filter { ($0.type == "url" || $0.type == "http" || $0.url != nil) && $0.infoHash == nil && $0.type != "torrent" && $0.type != "magnet" } ?? []
        guard let url = filtered.first?.url, let streamURL = URL(string: url) else { throw StreamError.noStreamAvailable }
        return streamURL
    }
}

// MARK: - StreamError
enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL
    var errorDescription: String? {
        switch self { case .noStreamAvailable: return "Không tìm thấy link stream"; case .invalidURL: return "URL không hợp lệ" }
    }
}

// MARK: - External Player
class ExternalPlayerManager {
    static let shared = ExternalPlayerManager()
    func open(_ name: String, url: String) {
        guard let e = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let s: String
        switch name {
        case "Infuse": s = "infuse://x-callback-url/play?url=\(e)"
        case "VLC": s = "vlc-x-callback://x-callback-url/stream?url=\(e)"
        case "Copy": UIPasteboard.general.string = url; return
        default: return
        }
        if let u = URL(string: s) { UIApplication.shared.open(u) }
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var selectedSource = 0
    @State private var player: AVPlayer?
    @State private var errorMessage: String?
    @State private var streamURL: String?
    @State private var sourceStatus: [Int: Bool] = [:]
    @State private var showSourceMenu = false
    
    var sq: String { movieTitle.replacingOccurrences(of: " ", with: "+") }
    
    var sources: [(String, Bool, String)] {[
        ("NTL Stream", true, ""),
        ("MediaFusion", true, ""),
        ("VidLink", false, "https://vidlink.pro/movie/\(movieId)"),
        ("MultiEmbed", false, "https://multiembed.mov/directstream.php?video_id=\(movieId)&tmdb=1"),
        ("Fmovies", false, "https://fmovies.ps/filter?keyword=\(sq)"),
        ("Sflix", false, "https://sflix.to/search/\(sq)"),
        ("HydraHD", false, "https://hydrahd.me/search?q=\(sq)"),
        ("PhimCN", false, "https://phimcn.site/search?keyword=\(sq)"),
        ("Motphim", false, "https://motphimtv.com/tim-kiem?q=\(sq)"),
    ]}
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Đợi Mew tí...").foregroundColor(.white.opacity(0.7)).font(.headline)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
                    Text(errorMessage).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                    
                    // Grid chọn nguồn đẹp
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<sources.count, id: \.self) { i in
                            Button {
                                selectedSource = i; loadSource()
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: sourceStatus[i] == true ? "checkmark.circle.fill" : (sourceStatus[i] == false ? "xmark.circle.fill" : "circle"))
                                        .font(.system(size: 20))
                                        .foregroundColor(sourceStatus[i] == true ? .green : (sourceStatus[i] == false ? .red : .gray))
                                    Text(sources[i].0.components(separatedBy: " ").first ?? "")
                                        .font(.system(size: 10)).foregroundColor(.white).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedSource == i ? .white.opacity(0.15) : .ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedSource == i ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Button("Thử lại") { loadSource() }
                            .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(.ultraThinMaterial)).font(.caption)
                        if let url = streamURL {
                            Menu {
                                Button("VLC") { ExternalPlayerManager.shared.open("VLC", url: url) }
                                Button("Infuse") { ExternalPlayerManager.shared.open("Infuse", url: url) }
                                Button("Copy Link") { ExternalPlayerManager.shared.open("Copy", url: url) }
                            } label: {
                                Label("Mở bằng...", systemImage: "arrow.up.forward.app")
                                    .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10)
                                    .background(Capsule().fill(.orange.opacity(0.6))).font(.caption)
                            }
                        }
                    }
                }
            } else if let player = player {
                FullScreenPlayer(player: player).ignoresSafeArea()
                    .onAppear { player.play(); lockToLandscape() }
                    .onDisappear { player.pause(); unlockOrientation() }
                    .overlay(alignment: .topTrailing) {
                        Button { showSourceMenu = true } label: {
                            ZStack {
                                Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                                Text(sources[selectedSource].0.components(separatedBy: " ").first ?? "")
                                    .font(.system(size: 8)).foregroundColor(.white)
                            }
                        }
                        .padding(.top, 50).padding(.trailing, 16)
                    }
            } else {
                FullScreenWebView(urlString: sources[selectedSource].2).ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        Button { showSourceMenu = true } label: {
                            ZStack {
                                Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                                Text(sources[selectedSource].0.components(separatedBy: " ").first ?? "")
                                    .font(.system(size: 8)).foregroundColor(.white)
                            }
                        }
                        .padding(.top, 50).padding(.trailing, 16)
                    }
            }
        }
        .onAppear { lockToLandscape() }
        .onDisappear { unlockOrientation() }
        .task { loadSource() }
        .sheet(isPresented: $showSourceMenu) {
            SourceMenuView(sources: sources, selectedSource: $selectedSource, sourceStatus: $sourceStatus, onSelect: { loadSource() })
        }
    }
    
    func loadSource() {
        isLoading = true; errorMessage = nil; player = nil; streamURL = nil
        sourceStatus[selectedSource] = nil
        if sources[selectedSource].1 {
            loadDirect()
        } else {
            isLoading = false
            sourceStatus[selectedSource] = true
        }
    }
    
    func loadDirect() {
        Task {
            do {
                let imdbId = try await fetchIMDb()
                let url: URL = selectedSource == 0 ? try await fetchNTL(imdbId) : try await MediaFusionManager.shared.getBestURL(imdbId: imdbId)
                await MainActor.run {
                    self.streamURL = url.absoluteString
                    self.player = AVPlayer(url: url)
                    self.sourceStatus[selectedSource] = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.sourceStatus[selectedSource] = false
                    self.isLoading = false
                }
            }
        }
    }
    
    func fetchNTL(_ imdbId: String) async throws -> URL {
        let u = "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(imdbId).json"
        var req = URLRequest(url: URL(string: u)!); req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: req)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String? }
        let res = try JSONDecoder().decode(R.self, from: data)
        guard let url = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url, let vu = URL(string: url) else { throw StreamError.noStreamAvailable }
        return vu
    }
    
    func fetchIMDb() async throws -> String {
        let u = "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b"
        let (data, _) = try await URLSession.shared.data(from: URL(string: u)!)
        struct E: Codable { let imdb_id: String? }
        guard let id = try JSONDecoder().decode(E.self, from: data).imdb_id else { throw StreamError.noStreamAvailable }
        return id
    }
    
    func lockToLandscape() {
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    func unlockOrientation() {
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

// MARK: - Source Menu
struct SourceMenuView: View {
    let sources: [(String, Bool, String)]
    @Binding var selectedSource: Int
    @Binding var sourceStatus: [Int: Bool]
    let onSelect: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(0..<sources.count, id: \.self) { i in
                            Button {
                                selectedSource = i; onSelect(); dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedSource == i ? .white.opacity(0.2) : .clear)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: sourceStatus[i] == true ? "checkmark.circle.fill" : (sourceStatus[i] == false ? "xmark.circle.fill" : "play.circle.fill"))
                                            .font(.system(size: 24))
                                            .foregroundColor(sourceStatus[i] == true ? .green : (sourceStatus[i] == false ? .red : .white.opacity(0.6)))
                                    }
                                    Text(sources[i].0)
                                        .font(.system(size: 9)).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.center)
                                    if sourceStatus[i] == true { Text("✅ Hoạt động").font(.system(size: 8)).foregroundColor(.green) }
                                    else if sourceStatus[i] == false { Text("❌ Không hoạt động").font(.system(size: 8)).foregroundColor(.red) }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedSource == i ? .white.opacity(0.1) : .ultraThinMaterial)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Chọn nguồn phim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Xong") { dismiss() }.foregroundColor(.white) }
            }
        }
    }
}

// MARK: - Full Screen Player
struct FullScreenPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController(); c.player = player; c.showsPlaybackControls = true
        c.videoGravity = .resizeAspectFill; c.allowsPictureInPicturePlayback = true; c.canStartPictureInPictureAutomaticallyFromInline = true
        return c
    }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}

// MARK: - Full Screen WebView
struct FullScreenWebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration(); config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let pp = WKWebpagePreferences(); pp.allowsContentJavaScript = true; config.defaultWebpagePreferences = pp
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.backgroundColor = .black; wv.isOpaque = false; wv.scrollView.contentInsetAdjustmentBehavior = .never
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
        if let url = URL(string: urlString) { var req = URLRequest(url: url); req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent"); wv.load(req) }
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}