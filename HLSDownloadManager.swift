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
        case downloading, paused, completed, failed
    }
}

@MainActor
class HLSDownloadManager: NSObject, ObservableObject, AVAssetDownloadDelegate {
    static let shared = HLSDownloadManager()
    @Published var downloads: [DownloadItem] = []
    
    private var session: AVAssetDownloadURLSession!
    private var activeTasks: [String: AVAssetDownloadTask] = [:]
    private let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.emcc.hlsdownload")
        config.allowsCellularAccess = true
        session = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: .main)
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
        
        let asset = AVURLAsset(url: url)
        if let task = session.makeAssetDownloadTask(asset: asset, assetTitle: title, assetArtworkData: nil, options: nil) {
            task.taskDescription = id
            activeTasks[id] = task
            task.resume()
        }
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
            UserDefaults.standard.set(data, forKey: "hls_downloads")
        }
    }
    
    private func loadDownloads() {
        if let data = UserDefaults.standard.data(forKey: "hls_downloads"),
           let items = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            downloads = items
            for i in 0..<downloads.count where downloads[i].status == .downloading {
                downloads[i].status = .paused
            }
        }
    }
    
    // MARK: - AVAssetDownloadDelegate
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard let id = assetDownloadTask.taskDescription,
              let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        
        let destDir = docsDir.appendingPathComponent("Downloads/\(id)", isDirectory: true)
        try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: location, includingPropertiesForKeys: nil)
            for file in files {
                let dest = destDir.appendingPathComponent(file.lastPathComponent)
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: file, to: dest)
            }
            downloads[idx].localURL = destDir.appendingPathComponent("master.m3u8")
            downloads[idx].status = .completed
            downloads[idx].progress = 1.0
        } catch {
            downloads[idx].status = .failed
        }
        activeTasks[id] = nil
        saveDownloads()
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard let id = assetDownloadTask.taskDescription,
              let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        
        let expected = timeRangeExpectedToLoad.duration.seconds
        let loaded = loadedTimeRanges.reduce(0.0) { $0 + $1.timeRangeValue.duration.seconds }
        downloads[idx].progress = expected > 0 ? min(loaded / expected, 1.0) : 0
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, let id = task.taskDescription,
           let idx = downloads.firstIndex(where: { $0.id == id }) {
            if (error as NSError).code != NSURLErrorCancelled {
                downloads[idx].status = .failed
                saveDownloads()
            }
        }
    }
}