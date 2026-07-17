import Foundation
import AVFoundation

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadInfo] = [:]
    @Published var downloadedMovies: [DownloadedMovie] = []
    
    private var downloadSession: AVAssetDownloadURLSession!
    private let backgroundIdentifier = "com.emmew.backgroundDownload"
    private let downloadedKey = "downloadedMovies"
    
    struct DownloadInfo {
        var progress: Double = 0
        var status: DownloadStatus = .waiting
        var task: AVAssetDownloadTask?
    }
    
    enum DownloadStatus {
        case waiting, downloading, paused, completed, failed
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
    }
    
    func startDownload(url: URL, movieId: Int, title: String, posterPath: String?, mediaType: String?, season: Int? = nil, episode: Int? = nil, episodeName: String? = nil) {
        let asset = AVURLAsset(url: url)
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
        
        guard activeDownloads[key] == nil else { return }
        
        let task = downloadSession.makeAssetDownloadTask(asset: asset, assetTitle: title, assetArtworkData: nil, options: nil)
        task?.resume()
        
        activeDownloads[key] = DownloadInfo(task: task, status: .downloading)
    }
    
    func pauseDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
        activeDownloads[key]?.task?.suspend()
        activeDownloads[key]?.status = .paused
    }
    
    func resumeDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
        activeDownloads[key]?.task?.resume()
        activeDownloads[key]?.status = .downloading
    }
    
    func cancelDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
        activeDownloads[key]?.task?.cancel()
        activeDownloads.removeValue(forKey: key)
    }
    
    func isDownloaded(movieId: Int, season: Int?, episode: Int?) -> Bool {
        downloadedMovies.contains { $0.id == movieId && $0.season == season && $0.episode == episode }
    }
    
    func getLocalURL(movieId: Int, season: Int?, episode: Int?) -> URL? {
        downloadedMovies.first { $0.id == movieId && $0.season == season && $0.episode == episode }?.localPlayURL
    }
    
    func deleteDownload(movieId: Int, season: Int?, episode: Int?) {
        downloadedMovies.removeAll { $0.id == movieId && $0.season == season && $0.episode == episode }
        saveDownloadedMovies()
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
        // Lưu file đã tải
        // location là file .movpkg, cần copy đến thư mục Documents
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsPath.appendingPathComponent(UUID().uuidString + ".movpkg")
        
        try? fileManager.moveItem(at: location, to: destinationURL)
        
        // Tìm thông tin download
        if let key = activeDownloads.first(where: { $0.value.task == assetDownloadTask })?.key {
            activeDownloads[key]?.status = .completed
            activeDownloads[key]?.progress = 1.0
            
            // Lưu vào danh sách (cần thêm thông tin movie vào đây)
            // ...
            saveDownloadedMovies()
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        let progress = timeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        if let key = activeDownloads.first(where: { $0.value.task == assetDownloadTask })?.key {
            activeDownloads[key]?.progress = progress
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed: \(error.localizedDescription)")
            if let key = activeDownloads.first(where: { $0.value.task == task })?.key {
                activeDownloads[key]?.status = .failed
            }
        }
    }
}