import SwiftUI
import AVKit

// MARK: - MovieSource
enum MovieSource: String, CaseIterable {
    case ntl = "NTL Stream"
    case mediafusion = "MediaFusion"
    case yastream = "YasStream"
    case vidlink = "VidLink"
    case multiembed = "MultiEmbed"
    case fmovies = "Fmovies"
    case sflix = "Sflix"
    case hydrahd = "HydraHD"
    case phimcn = "PhimCN"
    case motphim = "Motphim"
    
    var manifestURL: String? {
        switch self {
        case .mediafusion: return "https://mediafusion.elfhosted.com/manifest.json"
        case .yastream: return "https://yastream.tamthai.de/manifest.json"
        default: return nil
        }
    }
    
    var isDirect: Bool { self == .ntl || self == .mediafusion || self == .yastream }
}

// MARK: - StreamError
enum StreamError: Error, LocalizedError {
    case noStreamAvailable, invalidURL
    var errorDescription: String? {
        switch self { case .noStreamAvailable: return "Không tìm thấy link"; case .invalidURL: return "URL lỗi" }
    }
}

// MARK: - MovieStreamService
class MovieStreamService {
    static let shared = MovieStreamService()
    
    func getStreamURL(for source: MovieSource, imdbId: String) async throws -> URL {
        switch source {
        case .ntl: return try await fetchNTL(imdbId)
        case .mediafusion: return try await fetchMediaFusion(imdbId)
        case .yastream: return try await fetchStremio(manifest: source.manifestURL!, imdbId: imdbId)
        default: throw StreamError.noStreamAvailable
        }
    }
    
    private func fetchNTL(_ id: String) async throws -> URL {
        var r = URLRequest(url: URL(string: "https://tnluannguyen-ntl-stream.hf.space/stream/movie/\(id).json")!)
        r.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        let (d, _) = try await URLSession.shared.data(for: r)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String? }
        let res = try JSONDecoder().decode(R.self, from: d)
        guard let u = res.streams?.first(where: { $0.url != nil && !($0.url?.hasPrefix("magnet:") ?? true) })?.url, let vu = URL(string: u) else { throw StreamError.noStreamAvailable }
        return vu
    }
    
    private func fetchMediaFusion(_ id: String) async throws -> URL {
        let cleanId = id.replacingOccurrences(of: "tt", with: "")
        var r = URLRequest(url: URL(string: "https://mediafusion.elfhosted.com/stream/movie/\(cleanId).json")!)
        r.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        r.setValue("https://mediafusion.elfhosted.com/", forHTTPHeaderField: "Referer")
        let (d, _) = try await URLSession.shared.data(for: r)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String?; let type: String?; let infoHash: String? }
        let res = try JSONDecoder().decode(R.self, from: d)
        let filtered = res.streams?.filter { ($0.type == "url" || $0.type == "http") && $0.infoHash == nil && $0.type != "torrent" && $0.type != "magnet" } ?? []
        guard let u = filtered.first?.url, let vu = URL(string: u) else { throw StreamError.noStreamAvailable }
        return vu
    }
    
    private func fetchStremio(manifest: String, imdbId: String) async throws -> URL {
        let base = manifest.replacingOccurrences(of: "/manifest.json", with: "")
        let cleanId = imdbId.replacingOccurrences(of: "tt", with: "")
        var r = URLRequest(url: URL(string: "\(base)/stream/movie/\(cleanId).json")!)
        r.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        r.setValue(base, forHTTPHeaderField: "Referer")
        let (d, _) = try await URLSession.shared.data(for: r)
        struct R: Codable { let streams: [S]? }; struct S: Codable { let url: String?; let type: String?; let infoHash: String? }
        let res = try JSONDecoder().decode(R.self, from: d)
        let filtered = res.streams?.filter { ($0.type == "url" || $0.type == "http") && $0.infoHash == nil && $0.type != "torrent" && $0.type != "magnet" } ?? []
        guard let u = filtered.first?.url, let vu = URL(string: u) else { throw StreamError.noStreamAvailable }
        return vu
    }
}

// MARK: - MoviePlayerView
struct MoviePlayerView: View {
    let movieId: Int; let movieTitle: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var player: AVPlayer?
    @State private var selectedSource: MovieSource = .ntl
    @State private var sourceStatus: [MovieSource: Bool] = [:]
    @State private var showSourceMenu = false
    
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
                    
                    // Grid chọn nguồn
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(MovieSource.allCases, id: \.self) { source in
                            Button {
                                selectedSource = source
                                loadStream()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: sourceStatus[source] == true ? "checkmark.circle.fill" : (sourceStatus[source] == false ? "xmark.circle.fill" : "circle"))
                                        .font(.system(size: 18))
                                        .foregroundColor(sourceStatus[source] == true ? .green : (sourceStatus[source] == false ? .red : .gray))
                                    Text(source.rawValue)
                                        .font(.system(size: 9)).foregroundColor(.white).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(selectedSource == source ? .white.opacity(0.15) : .ultraThinMaterial))
                            }
                        }
                    }.padding(.horizontal)
                    
                    Button("Thử lại") { loadStream() }
                        .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                }
            } else if let player = player {
                CustomPlayerVC(player: player).ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
                    .overlay(alignment: .topTrailing) {
                        Button { showSourceMenu = true } label: {
                            Text(selectedSource.rawValue).font(.system(size: 9)).foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Capsule().fill(.ultraThinMaterial))
                        }
                        .padding(.top, 50).padding(.trailing, 16)
                    }
            }
        }
        .task { loadStream() }
        .sheet(isPresented: $showSourceMenu) {
            SourceMenuView(selectedSource: $selectedSource, sourceStatus: $sourceStatus, onSelect: { loadStream() })
        }
    }
    
    func loadStream() {
        isLoading = true; errorMessage = nil; player = nil; sourceStatus[selectedSource] = nil
        if selectedSource.isDirect {
            Task {
                do {
                    let imdbId = try await fetchIMDbId()
                    let url = try await MovieStreamService.shared.getStreamURL(for: selectedSource, imdbId: imdbId)
                    await MainActor.run {
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
        } else {
            // Web sources - dùng WebView
            isLoading = false
            sourceStatus[selectedSource] = true
        }
    }
    
    func fetchIMDbId() async throws -> String {
        let (d, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
        struct E: Codable { let imdb_id: String? }
        guard let id = try JSONDecoder().decode(E.self, from: d).imdb_id else { throw StreamError.noStreamAvailable }
        return id
    }
}

// MARK: - Source Menu
struct SourceMenuView: View {
    @Binding var selectedSource: MovieSource
    @Binding var sourceStatus: [MovieSource: Bool]
    let onSelect: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(MovieSource.allCases, id: \.self) { source in
                            Button {
                                selectedSource = source
                                onSelect()
                                dismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: sourceStatus[source] == true ? "checkmark.circle.fill" : (sourceStatus[source] == false ? "xmark.circle.fill" : "play.circle.fill"))
                                        .font(.system(size: 22))
                                        .foregroundColor(sourceStatus[source] == true ? .green : (sourceStatus[source] == false ? .red : .white.opacity(0.6)))
                                    Text(source.rawValue).font(.system(size: 9)).foregroundColor(.white).lineLimit(2)
                                    if sourceStatus[source] == true { Text("OK").font(.system(size: 8)).foregroundColor(.green) }
                                    else if sourceStatus[source] == false { Text("Lỗi").font(.system(size: 8)).foregroundColor(.red) }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(selectedSource == source ? .white.opacity(0.1) : .ultraThinMaterial))
                            }
                        }
                    }.padding()
                }
            }
            .navigationTitle("Chọn nguồn").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Xong") { dismiss() }.foregroundColor(.white) } }
        }
    }
}

// MARK: - Custom Player VC
struct CustomPlayerVC: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let c = AVPlayerViewController(); c.player = player; c.showsPlaybackControls = true
        c.videoGravity = .resizeAspect; c.allowsPictureInPicturePlayback = true; c.canStartPictureInPictureAutomaticallyFromInline = true; return c
    }
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
}