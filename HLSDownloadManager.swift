import Foundation
import AVFoundation

struct DownloadItem: Identifiable, Codable {
    let id: String
    let movieId: Int
    let movieTitle: String
    let posterPath: String?
    let mediaType: String?
    let seasonNumber: Int?
    let episodeNumber: Int?
    let streamURL: URL
    var progress: Double = 0
    var status: DownloadStatus = .downloading
    var localURL: URL?
    
    enum DownloadStatus: String, Codable {
        case downloading, completed, failed
    }
}

final class AtomicInteger {
    private(set) var value: Int = 0
    private let lock = NSLock()
    func increment() -> Int { lock.lock(); value += 1; let v = value; lock.unlock(); return v }
}

@MainActor
class HLSDownloadManager: NSObject, ObservableObject {
    static let shared = HLSDownloadManager()
    @Published var downloads: [DownloadItem] = []
    
    private let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let session = URLSession(configuration: {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 60
        c.timeoutIntervalForResource = 600
        return c
    }())
    
    override init() {
        super.init()
        URLProtocol.registerClass(LocalHLSProtocol.self)
        loadDownloads()
    }
    
    func startDownload(url: URL, movieId: Int, title: String, posterPath: String?, mediaType: String? = nil, season: Int? = nil, episode: Int? = nil) {
        let id = "\(movieId)_\(season ?? 0)_\(episode ?? 0)"
        guard !downloads.contains(where: { $0.id == id && $0.status == .completed }) else { return }
        
        let item = DownloadItem(id: id, movieId: movieId, movieTitle: title, posterPath: posterPath, mediaType: mediaType, seasonNumber: season, episodeNumber: episode, streamURL: url)
        
        if let idx = downloads.firstIndex(where: { $0.id == id }) { downloads[idx] = item }
        else { downloads.append(item) }
        saveDownloads()
        downloadPlaylist(id: id, url: url)
    }
    
    private func downloadPlaylist(id: String, url: URL) {
        var req = URLRequest(url: url)
        req.setValue("application/vnd.apple.mpegurl", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: req) { [weak self] data, _, error in
            guard let data, error == nil, let content = String(data: data, encoding: .utf8) else {
                Task { @MainActor [weak self] in self?.failDownload(id: id) }
                return
            }
            
            // Chọn variant cao nhất nếu là master playlist
            let finalURL: URL
            if content.contains("#EXT-X-STREAM-INF:") {
                finalURL = Self.pickBestVariant(from: content, baseURL: url) ?? url
            } else {
                finalURL = url
            }
            
            let segs = Self.parseSegmentsStatic(content, baseURL: finalURL)
            guard !segs.isEmpty else {
                Task { @MainActor [weak self] in self?.failDownload(id: id) }
                return
            }
            Task { @MainActor [weak self] in self?.downloadAllSegments(id: id, segments: segs) }
        }.resume()
    }
    
    private static func pickBestVariant(from content: String, baseURL: URL) -> URL? {
        var bestBW = 0
        var bestURL: URL?
        var currentBW = 0
        for line in content.components(separatedBy: .newlines) {
            if line.contains("BANDWIDTH=") {
                currentBW = Int(line.components(separatedBy: "BANDWIDTH=").last?.components(separatedBy: ",").first ?? "0") ?? 0
            } else if !line.hasPrefix("#") && !line.isEmpty && currentBW > bestBW {
                bestBW = currentBW
                let t = line.trimmingCharacters(in: .whitespaces)
                bestURL = t.hasPrefix("http") ? URL(string: t) : URL(string: t, relativeTo: baseURL.deletingLastPathComponent())
            }
        }
        return bestURL
    }
    
    private static func parseSegmentsStatic(_ content: String, baseURL: URL) -> [URL] {
        var urls: [URL] = []
        let baseDir = baseURL.deletingLastPathComponent()
        for line in content.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty || t.hasPrefix("#") { continue }
            if t.hasSuffix(".ts") || t.hasSuffix(".m4s") {
                if let u = URL(string: t, relativeTo: t.hasPrefix("http") ? nil : baseDir) { urls.append(u) }
            }
        }
        return urls
    }
    
    private func downloadAllSegments(id: String, segments: [URL]) {
        let destDir = docsDir.appendingPathComponent("Downloads/\(id)", isDirectory: true)
        try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        
        let total = segments.count
        let counter = AtomicInteger()
        let group = DispatchGroup()
        
        for (i, segURL) in segments.enumerated() {
            group.enter()
            var req = URLRequest(url: segURL)
            req.setValue("video/mp2t", forHTTPHeaderField: "Accept")
            
            session.dataTask(with: req) { [weak self] data, _, error in
                defer { group.leave() }
                guard let self else { return }
                if let data, error == nil {
                    try? data.write(to: destDir.appendingPathComponent("segment_\(i).ts"))
                    let done = counter.increment()
                    Task { @MainActor in
                        if let idx = self.downloads.firstIndex(where: { $0.id == id }) {
                            self.downloads[idx].progress = Double(done) / Double(total)
                        }
                    }
                }
            }.resume()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            
            // Tạo local playlist dùng scheme localhls://
            var playlist = "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:10\n#EXT-X-MEDIA-SEQUENCE:0\n#EXT-X-PLAYLIST-TYPE:VOD\n"
            for i in 0..<total {
                let segPath = destDir.appendingPathComponent("segment_\(i).ts").path
                playlist += "#EXTINF:10.0,\n"
                playlist += "\(LocalHLSProtocol.scheme)://localhost\(segPath)\n"
            }
            playlist += "#EXT-X-ENDLIST\n"
            
            let playlistURL = destDir.appendingPathComponent("playlist.m3u8")
            try? playlist.write(to: playlistURL, atomically: true, encoding: .utf8)
            
            Task { @MainActor in
                if let idx = self.downloads.firstIndex(where: { $0.id == id }) {
                    if counter.value == total {
                        self.downloads[idx].status = .completed
                        self.downloads[idx].progress = 1.0
                        self.downloads[idx].localURL = playlistURL
                    } else { self.downloads[idx].status = .failed }
                    self.saveDownloads()
                }
            }
        }
    }
    
    private func failDownload(id: String) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) { downloads[idx].status = .failed }
        saveDownloads()
    }
    
    func cancel(_ id: String) { failDownload(id: id) }
    
    func delete(_ id: String) {
        if let item = downloads.first(where: { $0.id == id }), let url = item.localURL {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        downloads.removeAll { $0.id == id }
        saveDownloads()
    }
    
    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) { UserDefaults.standard.set(data, forKey: "hls_v7") }
    }
    
    private func loadDownloads() {
        if let data = UserDefaults.standard.data(forKey: "hls_v7"),
           let items = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            downloads = items
            for i in 0..<downloads.count where downloads[i].status == .downloading { downloads[i].status = .failed }
        }
    }
}