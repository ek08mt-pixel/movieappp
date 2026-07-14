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
class HLSDownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = HLSDownloadManager()
    @Published var downloads: [DownloadItem] = []
    
    private let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private var pendingSegments: [String: [URL]] = [:]
    private var completedSegments: [String: Int] = [:]
    private var totalSegments: [String: Int] = [:]
    private lazy var session: URLSession = {
    let config = URLSessionConfiguration.default
    return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
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
        
        // Tải playlist m3u8 trước
        let task = session.downloadTask(with: url)
        task.taskDescription = "playlist_\(id)"
        activeTasks[id] = task
        task.resume()
    }
    
    private func downloadSegments(from playlistData: Data, baseURL: URL, id: String) {
        guard let content = String(data: playlistData, encoding: .utf8) else {
            failDownload(id: id)
            return
        }
        
        var segmentURLs: [URL] = []
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") && trimmed.hasSuffix(".ts") {
                let segmentURL: URL
                if trimmed.hasPrefix("http") {
                    segmentURL = URL(string: trimmed)!
                } else {
                    segmentURL = baseURL.deletingLastPathComponent().appendingPathComponent(trimmed)
                }
                segmentURLs.append(segmentURL)
            }
        }
        
        guard !segmentURLs.isEmpty else {
            failDownload(id: id)
            return
        }
        
        pendingSegments[id] = segmentURLs
        totalSegments[id] = segmentURLs.count
        completedSegments[id] = 0
        
        // Tải từng segment
        for (index, segURL) in segmentURLs.enumerated() {
            let task = session.downloadTask(with: segURL)
            task.taskDescription = "segment_\(id)_\(index)"
            task.resume()
        }
    }
    
    private func checkAllSegmentsDone(id: String) {
        let completed = completedSegments[id] ?? 0
        let total = totalSegments[id] ?? 0
        
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].progress = total > 0 ? Double(completed) / Double(total) : 0
        }
        
        if completed >= total && total > 0 {
            completeDownload(id: id)
        }
    }
    
    private func completeDownload(id: String) {
        guard let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        
        // Tạo local m3u8 playlist với relative paths
        let destDir = docsDir.appendingPathComponent("Downloads/\(id)", isDirectory: true)
        let localPlaylist = destDir.appendingPathComponent("playlist.m3u8")
        
        var playlistContent = "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:10\n#EXT-X-MEDIA-SEQUENCE:0\n"
        let total = totalSegments[id] ?? 0
        for i in 0..<total {
            playlistContent += "#EXTINF:10.0,\n"
            playlistContent += "segment_\(i).ts\n"
        }
        playlistContent += "#EXT-X-ENDLIST\n"
        
        try? playlistContent.write(to: localPlaylist, atomically: true, encoding: .utf8)
        
        downloads[idx].localURL = localPlaylist
        downloads[idx].status = .completed
        downloads[idx].progress = 1.0
        saveDownloads()
    }
    
    private func failDownload(id: String) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].status = .failed
        }
        saveDownloads()
    }
    
    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let desc = downloadTask.taskDescription else { return }
        
        if desc.hasPrefix("playlist_") {
            let id = String(desc.dropFirst("playlist_".count))
            guard let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
            
            let destDir = docsDir.appendingPathComponent("Downloads/\(id)", isDirectory: true)
            try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            
            if let data = try? Data(contentsOf: location) {
                downloadSegments(from: data, baseURL: downloads[idx].streamURL, id: id)
            } else {
                failDownload(id: id)
            }
        } else if desc.hasPrefix("segment_") {
            let parts = desc.components(separatedBy: "_")
            guard parts.count >= 3 else { return }
            let id = parts[1]
            let segIndex = parts[2]
            
            let destDir = docsDir.appendingPathComponent("Downloads/\(id)", isDirectory: true)
            let destFile = destDir.appendingPathComponent("segment_\(segIndex).ts")
            try? FileManager.default.removeItem(at: destFile)
            try? FileManager.default.moveItem(at: location, to: destFile)
            
            completedSegments[id] = (completedSegments[id] ?? 0) + 1
            checkAllSegmentsDone(id: id)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, let desc = task.taskDescription {
            if desc.hasPrefix("segment_") {
                let parts = desc.components(separatedBy: "_")
                if parts.count >= 3 {
                    let id = parts[1]
                    if (error as NSError).code != NSURLErrorCancelled {
                        failDownload(id: id)
                    }
                }
            } else if desc.hasPrefix("playlist_") {
                let id = String(desc.dropFirst("playlist_".count))
                if (error as NSError).code != NSURLErrorCancelled {
                    failDownload(id: id)
                }
            }
        }
    }
    
    func cancel(_ id: String) {
        activeTasks[id]?.cancel()
        activeTasks[id] = nil
        pendingSegments[id] = nil
        failDownload(id: id)
    }
    
    func delete(_ id: String) {
        activeTasks[id]?.cancel()
        activeTasks[id] = nil
        pendingSegments[id] = nil
        if let idx = downloads.firstIndex(where: { $0.id == id }), let url = downloads[idx].localURL {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        downloads.removeAll { $0.id == id }
        completedSegments[id] = nil
        totalSegments[id] = nil
        saveDownloads()
    }
    
    private func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: "hls_downloads_v4")
        }
    }
    
    private func loadDownloads() {
        if let data = UserDefaults.standard.data(forKey: "hls_downloads_v4"),
           let items = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            downloads = items
            for i in 0..<downloads.count where downloads[i].status == .downloading {
                downloads[i].status = .failed
            }
        }
    }
}