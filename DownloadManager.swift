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
    var progress: Double = 0
    var status: DownloadStatus = .downloading
    var fileURL: URL?
    var fileSize: Int64 = 0
    var downloadedSize: Int64 = 0
    
    enum DownloadStatus: String, Codable {
        case downloading, paused, completed, failed
    }
}

class DownloadManager: NSObject, ObservableObject, AVAssetDownloadDelegate {
    static let shared = DownloadManager()
    @Published var downloads: [DownloadItem] = []
    @Published var progress: [String: Double] = [:]
    
    private var session: AVAssetDownloadURLSession!
    private var activeDownloads: [String: AVAssetDownloadTask] = [:]
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.emmew.hlsdownload")
        session = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: .main)
        loadDownloads()
    }
    
    func download(
        url: URL,
        movieId: Int,
        title: String,
        posterPath: String?,
        mediaType: String? = nil,
        season: Int? = nil,
        episode: Int? = nil
    ) {
        let id = "\(movieId)_\(season ?? 0)_\(episode ?? 0)"
        guard !downloads.contains(where: { $0.id == id && $0.status == .completed }) else { return }
        
        let item = DownloadItem(
            id: id, movieId: movieId, movieTitle: title,
            posterPath: posterPath, mediaType: mediaType,
            seasonNumber: season, episodeNumber: episode
        )
        
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx] = item
        } else {
            downloads.append(item)
        }
        save()
        
        let asset = AVURLAsset(url: url)
        let task = session.makeAssetDownloadTask(
            asset: asset,
            assetTitle: title,
            assetArtworkData: nil,
            options: nil
        )
        task?.taskDescription = id
        task?.resume()
        if let task = task {
            activeDownloads[id] = task
        }
    }
    
    func cancel(_ id: String) {
        activeDownloads[id]?.cancel()
        activeDownloads[id] = nil
        updateStatus(id, .failed)
    }
    
    func delete(_ id: String) {
        activeDownloads[id]?.cancel()
        activeDownloads[id] = nil
        if let item = downloads.first(where: { $0.id == id }),
           let url = item.fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        downloads.removeAll { $0.id == id }
        progress[id] = nil
        save()
    }
    
    private func updateStatus(_ id: String, _ status: DownloadItem.DownloadStatus) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].status = status
            save()
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: "downloaded_items_v2")
        }
    }
    
    private func loadDownloads() {
        if let data = UserDefaults.standard.data(forKey: "downloaded_items_v2"),
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
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dlDir = docs.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dlDir, withIntermediateDirectories: true)
        
        let dest = dlDir.appendingPathComponent("\(id).movpkg")
        try? FileManager.default.removeItem(at: dest)
        
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            downloads[idx].fileURL = dest
            downloads[idx].status = .completed
            downloads[idx].progress = 1.0
            progress[id] = 1.0
        } catch {
            downloads[idx].status = .failed
        }
        activeDownloads[id] = nil
        save()
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard let id = assetDownloadTask.taskDescription,
              let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        
        let duration = timeRangeExpectedToLoad.duration.seconds
        let loaded = loadedTimeRanges.reduce(0.0) { $0 + $1.timeRangeValue.duration.seconds }
        let p = duration > 0 ? loaded / duration : 0
        downloads[idx].progress = min(p, 1.0)
        progress[id] = min(p, 1.0)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, let id = task.taskDescription {
            let ns = error as NSError
            if ns.code != NSURLErrorCancelled {
                updateStatus(id, .failed)
            }
        }
    }
}