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
        let f = res.streams?.filter { ($0.type == "url" || $0.type == "http" || $0.url != nil) && $0.infoHash == nil && $0.type != "torrent" && $0.type != "magnet" } ?? []
        guard let url = f.first?.url, let u = URL(string: url) else { throw StreamError.noStreamAvailable }
        return u
    }
}

enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL
    var errorDescription: String? {
        switch self { case .noStreamAvailable: return "Không tìm thấy link"; case .invalidURL: return "URL lỗi" }
    }
}

class ExternalPlayerManager {
    static let shared = ExternalPlayerManager()
    func open(_ name: String, url: String) {
        guard let e = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let s: String
        switch name { case "Infuse": s = "infuse://x-callback-url/play?url=\(e)"; case "VLC": s = "vlc-x-callback://x-callback-url/stream?url=\(e)"; case "Copy": UIPasteboard.general.string = url; return; default: return }
        if let u = URL(string: s) { UIApplication.shared.open(u) }
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true; @State private var selectedSource = 0
    @State private var player: AVPlayer?; @State private var errorMessage: String?
    @State private var streamURL: String?; @State private var sourceStatus: [Int: Bool] = [:]
    @State private var showSourceMenu = false
    
    var sq: String { movieTitle.replacingOccurrences(of: " ", with: "+") }
    var sources: [(String, Bool, String)] {[
        ("NTL", true, ""), ("MediaFusion", true, ""),
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
            if isLoading { LoadingView() }
            else if let err = errorMessage { ErrorView3(err: err, status: $sourceStatus, sel: $selectedSource, url: streamURL, src: sources, retry: { loadSource() }, pick: { i in selectedSource = i; loadSource() }) }
            else if let p = player { PlayerView2(player: p, name: sources[selectedSource].0, tap: { showSourceMenu = true }) }
            else { WebView2(url: sources[selectedSource].2, name: sources[selectedSource].0, tap: { showSourceMenu = true }) }
        }
        .onAppear { lockToLandscape() }
        .onDisappear { unlockOrientation() }
        .task { loadSource() }
        .sheet(isPresented: $showSourceMenu) { SourceMenu4(src: sources, sel: $selectedSource, status: $sourceStatus, pick: { loadSource() }) }
    }
    
    func loadSource() { isLoading = true; errorMessage = nil; player = nil; streamURL = nil; sourceStatus[selectedSource] = nil
        if sources[selectedSource].1 { loadDirect() } else { isLoading = false; sourceStatus[selectedSource] = true } }
    func loadDirect() { Task { do { let id = try await fetchIMDb(); let url = selectedSource == 0 ? try await fetchNTL(id) : try await MediaFusionManager.shared.getBestURL(imdbId: id)
        await MainActor.run { streamURL = url.absoluteString; player = AVPlayer(url: url); sourceStatus[selectedSource] = true; isLoading = false } }
        catch { await MainActor.run { errorMessage = error.localizedDescription; sourceStatus[selectedSource] = false; isLoading = false } } } }
    func fetchNTL(_ id: String) async throws -> URL { var r = URLRequest(url: URL(string: "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(id).json")!); r.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent"); let (d, _) = try await URLSession.shared.data(for: r); struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String? }; let res = try JSONDecoder().decode(R.self, from: d); guard let u = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url, let vu = URL(string: u) else { throw StreamError.noStreamAvailable }; return vu }
    func fetchIMDb() async throws -> String { let (d, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!); struct E: Codable { let imdb_id: String? }; guard let id = try JSONDecoder().decode(E.self, from: d).imdb_id else { throw StreamError.noStreamAvailable }; return id }
    func lockToLandscape() { UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation") }
    func unlockOrientation() { UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation") }
}

// MARK: - Small Views
struct LoadingView: View {
    var body: some View { VStack { ProgressView().tint(.white).scaleEffect(1.5); Text("Đợi Mew tí...").foregroundColor(.white.opacity(0.7)).font(.headline) } }
}
struct PlayerView2: View {
    let player: AVPlayer; let name: String; let tap: () -> Void
    var body: some View { FullScreenPlayer(player: player).ignoresSafeArea().overlay(alignment: .topTrailing) { Button(action: tap) { ZStack { Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36); Text(name).font(.system(size: 8)).foregroundColor(.white) } }.padding(.top, 50).padding(.trailing, 16) } }
}
struct WebView2: View {
    let url: String; let name: String; let tap: () -> Void
    var body: some View { FullScreenWebView(urlString: url).ignoresSafeArea().overlay(alignment: .topTrailing) { Button(action: tap) { ZStack { Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36); Text(name).font(.system(size: 8)).foregroundColor(.white) } }.padding(.top, 50).padding(.trailing, 16) } }
}
struct ErrorView3: View {
    let err: String; @Binding var status: [Int: Bool]; @Binding var sel: Int; let url: String?; let src: [(String, Bool, String)]; let retry: () -> Void; let pick: (Int) -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.gray)
            Text(err).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
            SourceGrid(src: src, sel: $sel, status: $status, pick: pick)
            HStack {
                Button("Thử lại", action: retry).foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial)).font(.caption)
                if let u = url { Menu { Button("VLC") { ExternalPlayerManager.shared.open("VLC", url: u) }; Button("Infuse") { ExternalPlayerManager.shared.open("Infuse", url: u) }; Button("Copy") { ExternalPlayerManager.shared.open("Copy", url: u) } } label: { Label("Mở...", systemImage: "arrow.up.forward.app").foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.orange.opacity(0.6))).font(.caption) } }
            }
        }
    }
}
struct SourceGrid: View {
    let src: [(String, Bool, String)]; @Binding var sel: Int; @Binding var status: [Int: Bool]; let pick: (Int) -> Void
    var body: some View { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) { ForEach(0..<src.count, id: \.self) { i in Button { pick(i) } label: { SourceCell(name: src[i].0, isSelected: sel == i, status: status[i]) } } }.padding(.horizontal) }
}
struct SourceCell: View {
    let name: String; let isSelected: Bool; let status: Bool?
    var icon: String { status == true ? "checkmark.circle.fill" : (status == false ? "xmark.circle.fill" : "circle") }
    var color: Color { status == true ? .green : (status == false ? .red : .gray) }
    var body: some View { VStack(spacing: 4) { Image(systemName: icon).font(.system(size: 18)).foregroundColor(color); Text(name).font(.system(size: 9)).foregroundColor(.white).lineLimit(1) }.frame(maxWidth: .infinity).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? .white.opacity(0.15) : .ultraThinMaterial)) }
}
struct SourceMenu4: View {
    let src: [(String, Bool, String)]; @Binding var sel: Int; @Binding var status: [Int: Bool]; let pick: () -> Void; @Environment(\.dismiss) var d
    var body: some View {
        NavigationStack { ZStack { Color.black.opacity(0.95).ignoresSafeArea()
            ScrollView { SourceMenuGrid(src: src, sel: $sel, status: $status, pick: pick, dismiss: d) }
        }.navigationTitle("Chọn nguồn").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Xong") { d() }.foregroundColor(.white) } } }
    }
}
struct SourceMenuGrid: View {
    let src: [(String, Bool, String)]; @Binding var sel: Int; @Binding var status: [Int: Bool]; let pick: () -> Void; let dismiss: DismissAction
    var body: some View { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(0..<src.count, id: \.self) { i in Button { sel = i; pick(); dismiss() } label: { SourceMenuCell(name: src[i].0, isSelected: sel == i, status: status[i]) } } }.padding() }
}
struct SourceMenuCell: View {
    let name: String; let isSelected: Bool; let status: Bool?
    var body: some View { VStack(spacing: 6) { Image(systemName: status == true ? "checkmark.circle.fill" : (status == false ? "xmark.circle.fill" : "play.circle.fill")).font(.system(size: 22)).foregroundColor(status == true ? .green : (status == false ? .red : .white.opacity(0.6))); Text(name).font(.system(size: 9)).foregroundColor(.white).lineLimit(2); if status == true { Text("OK").font(.system(size: 8)).foregroundColor(.green) } else if status == false { Text("Lỗi").font(.system(size: 8)).foregroundColor(.red) } }.frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? .white.opacity(0.1) : .ultraThinMaterial)) }
}
struct FullScreenPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController { let c = AVPlayerViewController(); c.player = player; c.showsPlaybackControls = true; c.videoGravity = .resizeAspectFill; c.allowsPictureInPicturePlayback = true; c.canStartPictureInPictureAutomaticallyFromInline = true; return c }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}
struct FullScreenWebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView { let config = WKWebViewConfiguration(); config.allowsInlineMediaPlayback = true; config.mediaTypesRequiringUserActionForPlayback = []; let pp = WKWebpagePreferences(); pp.allowsContentJavaScript = true; config.defaultWebpagePreferences = pp; let wv = WKWebView(frame: .zero, configuration: config); wv.backgroundColor = .black; wv.isOpaque = false; wv.scrollView.contentInsetAdjustmentBehavior = .never; wv.customUserAgent = "Mozilla/5.0"; if let url = URL(string: urlString) { var req = URLRequest(url: url); req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent"); wv.load(req) }; return wv }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}