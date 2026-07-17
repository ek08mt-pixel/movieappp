import Foundation
import AVFoundation

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadInfo] = [:]
    @Published var downloadedMovies: [DownloadedMovie] = []
    
    private var downloadSession: AVAssetDownloadURLSession!
    private let downloadedKey = "downloadedMovies"
    
    private var pendingMetadata: [String: PendingDownloadMetadata] = [:]
    
    struct DownloadInfo {
        var progress: Double = 0
        var status: DownloadStatus = .waiting
    }
    
    enum DownloadStatus {
        case waiting, downloading, paused, completed, failed
    }
    
    struct PendingDownloadMetadata {
        let id: Int; let title: String; let posterPath: String?
        let mediaType: String?; let season: Int?; let episode: Int?; let episodeName: String?
    }
    
    struct DownloadedMovie: Codable, Identifiable {
        let id: Int; let title: String; let posterPath: String?
        let mediaType: String?; let season: Int?; let episode: Int?
        let episodeName: String?; let localURL: String; let fileSize: Int64
        var localPlayURL: URL? { URL(string: localURL) }
    }
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.emmew.avdownload")
        downloadSession = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: .main)
        loadDownloadedMovies()
    }
    
    func startDownload(url: URL, movieId: Int, title: String, posterPath: String?, mediaType: String?, season: Int? = nil, episode: Int? = nil, episodeName: String? = nil) {
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
        guard activeDownloads[key] == nil else { return }
        
        let asset = AVURLAsset(url: url)
        guard let task = downloadSession.makeAssetDownloadTask(asset: asset, assetTitle: "\(title) S\(season ?? 0)E\(episode ?? 0)", assetArtworkData: nil, options: nil) else { return }
        task.resume()
        
        pendingMetadata[key] = PendingDownloadMetadata(id: movieId, title: title, posterPath: posterPath, mediaType: mediaType, season: season, episode: episode, episodeName: episodeName)
        activeDownloads[key] = DownloadInfo(progress: 0, status: .downloading)
    }
    
    func pauseDownload(movieId: Int, season: Int?, episode: Int?) { /* TODO */ }
    func resumeDownload(movieId: Int, season: Int?, episode: Int?) { /* TODO */ }
    func cancelDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
        activeDownloads[key] = nil; pendingMetadata.removeValue(forKey: key)
    }
    
    func isDownloaded(movieId: Int, season: Int?, episode: Int?) -> Bool {
        downloadedMovies.contains { $0.id == movieId && $0.season == season && $0.episode == episode }
    }
    
    func getLocalURL(movieId: Int, season: Int?, episode: Int?) -> URL? {
        downloadedMovies.first { $0.id == movieId && $0.season == season && $0.episode == episode }?.localPlayURL
    }
    
    func deleteDownload(movieId: Int, season: Int?, episode: Int?) {
        if let url = getLocalURL(movieId: movieId, season: season, episode: episode) {
            try? FileManager.default.removeItem(at: url)
        }
        downloadedMovies.removeAll { $0.id == movieId && $0.season == season && $0.episode == episode }
        saveDownloadedMovies()
    }
    
    func downloadStatus(movieId: Int, season: Int?, episode: Int?) -> DownloadStatus {
        if isDownloaded(movieId: movieId, season: season, episode: episode) { return .completed }
        return activeDownloads["\(movieId)_S\(season ?? 0)E\(episode ?? 0)"]?.status ?? .waiting
    }
    
    func downloadProgress(movieId: Int, season: Int?, episode: Int?) -> Double {
        if isDownloaded(movieId: movieId, season: season, episode: episode) { return 1.0 }
        return activeDownloads["\(movieId)_S\(season ?? 0)E\(episode ?? 0)"]?.progress ?? 0
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
}

extension DownloadManager: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        let key = pendingMetadata.first(where: { $0.key.contains("_S") })?.key ?? ""
        guard let meta = pendingMetadata[key] else { return }
        
        let destURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(UUID().uuidString + ".movpkg")
        
        try? FileManager.default.moveItem(at: location, to: destURL)
        
        let movie = DownloadedMovie(id: meta.id, title: meta.title, posterPath: meta.posterPath, mediaType: meta.mediaType, season: meta.season, episode: meta.episode, episodeName: meta.episodeName, localURL: destURL.absoluteString, fileSize: 0)
        
        downloadedMovies.removeAll { $0.id == meta.id && $0.season == meta.season && $0.episode == meta.episode }
        downloadedMovies.append(movie)
        activeDownloads[key]?.status = .completed
        activeDownloads[key]?.progress = 1.0
        pendingMetadata.removeValue(forKey: key)
        saveDownloadedMovies()
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        let progress = timeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        if let key = pendingMetadata.first?.key {
            activeDownloads[key]?.progress = min(progress, 1.0)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError?, error.code != NSURLErrorCancelled {
            if let key = pendingMetadata.first?.key {
                activeDownloads[key]?.status = .failed
            }
        }
    }
}