import Foundation
import AVFoundation

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadInfo] = [:]
    @Published var downloadedMovies: [DownloadedMovie] = []
    
    private var downloadSession: AVAssetDownloadURLSession!
    private let backgroundIdentifier = "com.emmew.backgroundDownload"
    private let downloadedKey = "downloadedMovies"
    
    // Lưu metadata tạm thời trong quá trình tải
    private var pendingMetadata: [String: PendingDownloadMetadata] = [:]
    
    struct DownloadInfo {
        var progress: Double = 0
        var status: DownloadStatus = .waiting
        var task: AVAssetDownloadTask?
    }
    
    enum DownloadStatus {
        case waiting, downloading, paused, completed, failed
    }
    
    struct PendingDownloadMetadata {
        let id: Int
        let title: String
        let posterPath: String?
        let mediaType: String?
        let season: Int?
        let episode: Int?
        let episodeName: String?
    }
    
    struct DownloadedMovie: Codable, Identifiable {
        let id: Int
        let title: String
        let posterPath: String?
        let mediaType: String?
        let season: Int?
        let episode: Int?
        let episodeName: String?
        let localURL: String
        let fileSize: Int64
        
        var localPlayURL: URL? { URL(string: localURL) }
    }
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: backgroundIdentifier)
        downloadSession = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: .main)
        loadDownloadedMovies()
        restorePendingDownloads()
    }
    
    func startDownload(url: URL, movieId: Int, title: String, posterPath: String?, mediaType: String?, season: Int? = nil, episode: Int? = nil, episodeName: String? = nil) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        
        guard activeDownloads[key] == nil else { return }
        
        let asset = AVURLAsset(url: url)
        
        guard let task = downloadSession.makeAssetDownloadTask(
            asset: asset,
            assetTitle: "\(title) S\(season ?? 0)E\(episode ?? 0)",
            assetArtworkData: nil,
            options: nil
        ) else {
            print("Failed to create download task")
            return
        }
        
        // Lưu metadata để dùng khi tải xong
        pendingMetadata[key] = PendingDownloadMetadata(
            id: movieId,
            title: title,
            posterPath: posterPath,
            mediaType: mediaType,
            season: season,
            episode: episode,
            episodeName: episodeName
        )
        
        task.resume()
        
        activeDownloads[key] = DownloadInfo(progress: 0, status: .downloading, task: task)
    }
    
    func pauseDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        activeDownloads[key]?.task?.suspend()
        activeDownloads[key]?.status = .paused
    }
    
    func resumeDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        activeDownloads[key]?.task?.resume()
        activeDownloads[key]?.status = .downloading
    }
    
    func cancelDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        activeDownloads[key]?.task?.cancel()
        activeDownloads.removeValue(forKey: key)
        pendingMetadata.removeValue(forKey: key)
    }
    
    func isDownloaded(movieId: Int, season: Int?, episode: Int?) -> Bool {
        downloadedMovies.contains { $0.id == movieId && $0.season == season && $0.episode == episode }
    }
    
    func getLocalURL(movieId: Int, season: Int?, episode: Int?) -> URL? {
        downloadedMovies.first { $0.id == movieId && $0.season == season && $0.episode == episode }?.localPlayURL
    }
    
    func deleteDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        if let localURL = getLocalURL(movieId: movieId, season: season, episode: episode) {
            try? FileManager.default.removeItem(at: localURL)
        }
        downloadedMovies.removeAll { $0.id == movieId && $0.season == season && $0.episode == episode }
        activeDownloads.removeValue(forKey: key)
        pendingMetadata.removeValue(forKey: key)
        saveDownloadedMovies()
    }
    
    func downloadStatus(movieId: Int, season: Int?, episode: Int?) -> DownloadStatus {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        if isDownloaded(movieId: movieId, season: season, episode: episode) {
            return .completed
        }
        return activeDownloads[key]?.status ?? .waiting
    }
    
    func downloadProgress(movieId: Int, season: Int?, episode: Int?) -> Double {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        if isDownloaded(movieId: movieId, season: season, episode: episode) {
            return 1.0
        }
        return activeDownloads[key]?.progress ?? 0
    }
    
    private func downloadKey(movieId: Int, season: Int?, episode: Int?) -> String {
        "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
    }
    
    private func saveDownloadedMovies() {
        if let data = try? JSONEncoder().encode(downloadedMovies) {
            UserDefaults.standard.set(data, forKey: downloadedKey)
        }
    }
    
    private func loadDownloadedMovies() {
        if let data = UserDefaults.standard.data(forKey: downloadedKey),
           let movies = try? JSONDecoder().decode([DownloadedMovie].self, from: data) {
            downloadedMovies = movies
        }
    }
    
    private func restorePendingDownloads() {
        downloadSession.getAllTasks { tasks in
            for task in tasks {
                if let downloadTask = task as? AVAssetDownloadTask {
                    downloadTask.resume()
                }
            }
        }
    }
}

extension DownloadManager: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsPath.appendingPathComponent(UUID().uuidString + ".movpkg")
        
        do {
            // Xóa file cũ nếu có
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)
            
            // Lấy file size
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Tìm key và metadata
            if let key = findKey(for: assetDownloadTask),
               let metadata = pendingMetadata[key] {
                
                let downloadedMovie = DownloadedMovie(
                    id: metadata.id,
                    title: metadata.title,
                    posterPath: metadata.posterPath,
                    mediaType: metadata.mediaType,
                    season: metadata.season,
                    episode: metadata.episode,
                    episodeName: metadata.episodeName,
                    localURL: destinationURL.absoluteString,
                    fileSize: fileSize
                )
                
                // Thêm vào danh sách, tránh trùng lặp
                downloadedMovies.removeAll { $0.id == metadata.id && $0.season == metadata.season && $0.episode == metadata.episode }
                downloadedMovies.append(downloadedMovie)
                
                activeDownloads[key]?.status = .completed
                activeDownloads[key]?.progress = 1.0
                pendingMetadata.removeValue(forKey: key)
                
                saveDownloadedMovies()
                
                // Xóa task khỏi activeDownloads sau 3 giây
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.activeDownloads.removeValue(forKey: key)
                }
            }
        } catch {
            print("Failed to save downloaded file: \(error.localizedDescription)")
            if let key = findKey(for: assetDownloadTask) {
                activeDownloads[key]?.status = .failed
            }
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard timeRangeExpectedToLoad.duration.seconds > 0 else { return }
        let progress = min(timeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds, 1.0)
        if let key = findKey(for: assetDownloadTask) {
            activeDownloads[key]?.progress = progress
            activeDownloads[key]?.status = .downloading
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError? {
            // User cancelled - không tính là lỗi
            if error.code == NSURLErrorCancelled {
                return
            }
            print("Download failed: \(error.localizedDescription)")
            if let downloadTask = task as? AVAssetDownloadTask,
               let key = findKey(for: downloadTask) {
                activeDownloads[key]?.status = .failed
            }
        }
    }
    
    private func findKey(for task: AVAssetDownloadTask) -> String? {
        return activeDownloads.first(where: { $0.value.task == task })?.key
    }
}