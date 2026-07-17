import Foundation

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadInfo] = [:]
    @Published var downloadedMovies: [DownloadedMovie] = []
    
    private var downloadSession: URLSession!
    private let downloadedKey = "downloadedMovies"
    
    private var pendingMetadata: [String: PendingDownloadMetadata] = [:]
    private var downloadTasks: [String: URLSessionDataTask] = [:]
    
    struct DownloadInfo {
        var progress: Double = 0
        var status: DownloadStatus = .waiting
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
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 600
        downloadSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        loadDownloadedMovies()
    }
    
    func startDownload(url: URL, movieId: Int, title: String, posterPath: String?, mediaType: String?, season: Int? = nil, episode: Int? = nil, episodeName: String? = nil) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        
        guard activeDownloads[key] == nil || activeDownloads[key]?.status == .failed else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://phimapi.com", forHTTPHeaderField: "Referer")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        
        let task = downloadSession.dataTask(with: request)
        task.resume()
        downloadTasks[key] = task
        
        pendingMetadata[key] = PendingDownloadMetadata(
            id: movieId, title: title, posterPath: posterPath,
            mediaType: mediaType, season: season, episode: episode, episodeName: episodeName
        )
        
        activeDownloads[key] = DownloadInfo(progress: 0, status: .downloading)
    }
    
    func pauseDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        downloadTasks[key]?.cancel()
        downloadTasks.removeValue(forKey: key)
        activeDownloads[key]?.status = .paused
    }
    
    func resumeDownload(movieId: Int, season: Int?, episode: Int?) {
        // Không hỗ trợ resume với data task, tải lại từ đầu
        activeDownloads[downloadKey(movieId: movieId, season: season, episode: episode)]?.status = .waiting
    }
    
    func cancelDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        downloadTasks[key]?.cancel()
        downloadTasks.removeValue(forKey: key)
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
        if let localURL = getLocalURL(movieId: movieId, season: season, episode: episode) {
            try? FileManager.default.removeItem(at: localURL)
        }
        downloadedMovies.removeAll { $0.id == movieId && $0.season == season && $0.episode == episode }
        saveDownloadedMovies()
    }
    
    func downloadStatus(movieId: Int, season: Int?, episode: Int?) -> DownloadStatus {
        if isDownloaded(movieId: movieId, season: season, episode: episode) { return .completed }
        return activeDownloads[downloadKey(movieId: movieId, season: season, episode: episode)]?.status ?? .waiting
    }
    
    func downloadProgress(movieId: Int, season: Int?, episode: Int?) -> Double {
        if isDownloaded(movieId: movieId, season: season, episode: episode) { return 1.0 }
        return activeDownloads[downloadKey(movieId: movieId, season: season, episode: episode)]?.progress ?? 0
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
}

// MARK: - URLSessionDataDelegate
extension DownloadManager: URLSessionDataDelegate {
    private struct DownloadContext {
        var data = Data()
        var expectedSize: Int64 = 0
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let key = downloadTasks.first(where: { $0.value == dataTask })?.key else { return }
        // Lưu data vào file tạm
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent("\(key).m3u8")
        
        if fileManager.fileExists(atPath: tempURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: tempURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: tempURL)
        }
        
        // Cập nhật progress dựa trên expected content length
        if let existingData = try? Data(contentsOf: tempURL) {
            let progress = Double(existingData.count) / 10000.0 // ước lượng ~10KB
            activeDownloads[key]?.progress = min(progress, 0.99)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError? {
            print("❌ Download error: \(error.localizedDescription)")
            if let key = downloadTasks.first(where: { $0.value == task })?.key {
                activeDownloads[key]?.status = .failed
            }
            return
        }
        
        guard let key = downloadTasks.first(where: { $0.value == task })?.key,
              let metadata = pendingMetadata[key] else { return }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsPath.appendingPathComponent(UUID().uuidString + ".m3u8")
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent("\(key).m3u8")
        
        do {
            if fileManager.fileExists(atPath: tempURL.path) {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempURL, to: destinationURL)
            } else {
                // Không có data
                activeDownloads[key]?.status = .failed
                return
            }
            
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            let downloadedMovie = DownloadedMovie(
                id: metadata.id, title: metadata.title, posterPath: metadata.posterPath,
                mediaType: metadata.mediaType, season: metadata.season, episode: metadata.episode,
                episodeName: metadata.episodeName, localURL: destinationURL.absoluteString, fileSize: fileSize
            )
            
            downloadedMovies.removeAll { $0.id == metadata.id && $0.season == metadata.season && $0.episode == metadata.episode }
            downloadedMovies.append(downloadedMovie)
            
            activeDownloads[key]?.status = .completed
            activeDownloads[key]?.progress = 1.0
            pendingMetadata.removeValue(forKey: key)
            downloadTasks.removeValue(forKey: key)
            
            saveDownloadedMovies()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.activeDownloads.removeValue(forKey: key)
            }
        } catch {
            print("❌ Save error: \(error)")
            activeDownloads[key]?.status = .failed
        }
    }
}