import AVFoundation
import SwiftUI

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
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private lazy var session: URLSession = {
        URLSession(configuration: .default)
    }()
    
    override init() {
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
        
        let task = session.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self else { return }
            let idx = self.downloads.firstIndex(where: { $0.id == id })
            guard let idx = idx else { return }
            
            Task { @MainActor in
                if let localURL = localURL {
                    let destDir = self.docsDir.appendingPathComponent("Downloads/\(id)", isDirectory: true)
                    try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
                    let destFile = destDir.appendingPathComponent("video.m3u8")
                    try? FileManager.default.removeItem(at: destFile)
                    
                    do {
                        try FileManager.default.moveItem(at: localURL, to: destFile)
                        self.downloads[idx].localURL = destFile
                        self.downloads[idx].status = .completed
                        self.downloads[idx].progress = 1.0
                    } catch {
                        self.downloads[idx].status = .failed
                    }
                } else {
                    self.downloads[idx].status = .failed
                }
                self.saveDownloads()
            }
        }
        activeTasks[id] = task
        task.resume()
    }
    
    func cancel(_ id: String) {
        activeTasks[id]?.cancel()
        activeTasks[id] = nil
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].status = .failed
        }
        saveDownloads()
    }
    
    func delete(_ id: String) {
        activeTasks[id]?.cancel()
        activeTasks[id] = nil
        if let item = downloads.first(where: { $0.id == id }), let url = item.localURL {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        downloads.removeAll { $0.id == id }
        saveDownloads()
    }
    
    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: "hls_downloads_v3")
        }
    }
    
    private func loadDownloads() {
        if let data = UserDefaults.standard.data(forKey: "hls_downloads_v3"),
           let items = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            downloads = items
            for i in 0..<downloads.count where downloads[i].status == .downloading {
                downloads[i].status = .failed
            }
        }
    }
}