import Foundation
import AVFoundation
import WebKit

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

@MainActor
class HLSDownloadManager: NSObject, ObservableObject {
    static let shared = HLSDownloadManager()
    @Published var downloads: [DownloadItem] = []
    
    private let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let session: URLSession
    private var activeTasks: [String: (task: URLSessionDataTask, segments: [String], completed: Int)] = [:]
    
    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        session = URLSession(configuration: config)
        super.init()
        loadDownloads()
    }
    
    func startDownload(url: URL, movieId: Int, title: String, posterPath: String?, mediaType: String? = nil, season: Int? = nil, episode: Int? = nil) {
        let id = "\(movieId)_\(season ?? 0)_\(episode ?? 0)"
        guard !downloads.contains(where: { $0.id == id && $0.status == .completed }) else { return }
        
        let item = DownloadItem(id: id, movieId: movieId, movieTitle: title, posterPath: posterPath, mediaType: mediaType, seasonNumber: season, episodeNumber: episode, streamURL: url)
        
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx] = item
        } else {
            downloads.append(item)
        }
        saveDownloads()
        
        downloadPlaylist(id: id, url: url)
    }
    
    private func downloadPlaylist(id: String, url: URL) {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.apple.mpegurl", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil,
                  let content = String(data: data, encoding: .utf8) else {
                Task { @MainActor in self?.failDownload(id: id) }
                return
            }
            
            let segments = self.parseSegments(from: content, baseURL: url)
            guard !segments.isEmpty else {
                Task { @MainActor in self.failDownload(id: id) }
                return
            }
            
            Task { @MainActor in
                self.activeTasks[id] = (task: task, segments: segments, completed: 0)
                self.downloadAllSegments(id: id, segments: segments, baseURL: url)
            }
        }
        task.resume()
    }
    
    private func parseSegments(from content: String, baseURL: URL) -> [String] {
        var segments: [String] = []
        let lines = content.components(separatedBy: .newlines)
        let baseDir = baseURL.deletingLastPathComponent()
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                if trimmed.hasSuffix(".ts") || trimmed.hasSuffix(".m4s") {
                    if trimmed.hasPrefix("http") {
                        segments.append(trimmed)
                    } else if trimmed.hasPrefix("/") {
                        segments.append("\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")\(trimmed)")
                    } else {
                        segments.append(baseDir.appendingPathComponent(trimmed).absoluteString)
                    }
                }
            }
        }
        return segments
    }
    
    private func downloadAllSegments(id: String, segments: [String], baseURL: URL) {
    let destDir = docsDir.appendingPathComponent("Downloads/\(id)", isDirectory: true)
    try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
    
    var playlist = "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:10\n#EXT-X-MEDIA-SEQUENCE:0\n"
    for i in 0..<segments.count {
        playlist += "#EXTINF:10.0,\nsegment_\(i).ts\n"
    }
    playlist += "#EXT-X-ENDLIST\n"
    try? playlist.write(to: destDir.appendingPathComponent("playlist.m3u8"), atomically: true, encoding: .utf8)
    
    let total = segments.count
    let completedCount = AtomicInteger()
    let group = DispatchGroup()
    
    for (index, segURLStr) in segments.enumerated() {
        guard let segURL = URL(string: segURLStr) else { continue }
        
        group.enter()
        var request = URLRequest(url: segURL)
        request.setValue("video/mp2t", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: request) { data, response, error in
            defer { group.leave() }
            
            if let data = data, error == nil {
                let destFile = destDir.appendingPathComponent("segment_\(index).ts")
                try? data.write(to: destFile)
                let done = completedCount.increment()
                
                Task { @MainActor in
                    if let idx = self.downloads.firstIndex(where: { $0.id == id }) {
                        self.downloads[idx].progress = Double(done) / Double(total)
                    }
                }
            }
        }.resume()
    }
    
    group.notify(queue: .main) { [weak self] in
        guard let self = self else { return }
        Task { @MainActor in
            if let idx = self.downloads.firstIndex(where: { $0.id == id }) {
                if completedCount.value == total {
                    self.downloads[idx].status = .completed
                    self.downloads[idx].progress = 1.0
                    self.downloads[idx].localURL = destDir.appendingPathComponent("playlist.m3u8")
                } else {
                    self.downloads[idx].status = .failed
                }
                self.saveDownloads()
            }
            self.activeTasks[id] = nil
        }
    }
}

// Thêm class helper này ngoài struct
final class AtomicInteger {
    private var value: Int = 0
    private let lock = NSLock()
    
    func increment() -> Int {
        lock.lock()
        value += 1
        let v = value
        lock.unlock()
        return v
    }
}
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                if let idx = self.downloads.firstIndex(where: { $0.id == id }) {
                    if completed == total {
                        self.downloads[idx].status = .completed
                        self.downloads[idx].progress = 1.0
                        self.downloads[idx].localURL = destDir.appendingPathComponent("playlist.m3u8")
                    } else {
                        self.downloads[idx].status = .failed
                    }
                    self.saveDownloads()
                }
                self.activeTasks[id] = nil
            }
        }
    }
    
    private func failDownload(id: String) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].status = .failed
        }
        saveDownloads()
    }
    
    func cancel(_ id: String) {
        activeTasks[id] = nil
        failDownload(id: id)
    }
    
    func delete(_ id: String) {
        activeTasks[id] = nil
        if let item = downloads.first(where: { $0.id == id }), let url = item.localURL {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        downloads.removeAll { $0.id == id }
        saveDownloads()
    }
    
    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: "hls_downloads_v5")
        }
    }
    
    private func loadDownloads() {
        if let data = UserDefaults.standard.data(forKey: "hls_downloads_v5"),
           let items = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            downloads = items
            for i in 0..<downloads.count where downloads[i].status == .downloading {
                downloads[i].status = .failed
            }
        }
    }
}