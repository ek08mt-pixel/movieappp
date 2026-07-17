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
        let originalURL: String
        let fileSize: Int64
        
        var localPlayURL: URL? { URL(string: localURL) }
    }
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 3600
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
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
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
    let folderName = UUID().uuidString
    let folderURL = documentsPath.appendingPathComponent(folderName)
    let tempURL = fileManager.temporaryDirectory.appendingPathComponent("\(key).m3u8")
    
    // Chạy background
    DispatchQueue.global(qos: .background).async {
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            let content = try String(contentsOf: tempURL, encoding: .utf8)
            let originalURLString = task.originalRequest?.url?.absoluteString ?? ""
            let lines = content.components(separatedBy: .newlines)
            
            var modifiedLines: [String] = []
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.hasPrefix("#") && !trimmed.isEmpty && trimmed.hasSuffix(".m3u8") {
                    let subURL: URL
                    if trimmed.hasPrefix("http") {
                        subURL = URL(string: trimmed)!
                    } else if let origURL = URL(string: originalURLString) {
                        subURL = origURL.deletingLastPathComponent().appendingPathComponent(trimmed)
                    } else {
                        modifiedLines.append(line)
                        continue
                    }
                    
                    if let subData = try? Data(contentsOf: subURL),
                       let subContent = String(data: subData, encoding: .utf8) {
                        let subFileName = "sub.m3u8"
                        let subFileURL = folderURL.appendingPathComponent(subFileName)
                        try subContent.write(to: subFileURL, atomically: true, encoding: .utf8)
                        
                        let subLines = subContent.components(separatedBy: .newlines)
                        var subModifiedLines: [String] = []
                        let baseSubURL = subURL.deletingLastPathComponent()
                        
                        for subLine in subLines {
                            let subTrimmed = subLine.trimmingCharacters(in: .whitespaces)
                            if !subTrimmed.hasPrefix("#") && !subTrimmed.isEmpty && subTrimmed.hasSuffix(".ts") {
                                let segmentURL: URL
                                if subTrimmed.hasPrefix("http") {
                                    segmentURL = URL(string: subTrimmed)!
                                } else {
                                    segmentURL = baseSubURL.appendingPathComponent(subTrimmed)
                                }
                                
                                let segFileName = segmentURL.lastPathComponent
                                let segFileURL = folderURL.appendingPathComponent(segFileName)
                                if let segData = try? Data(contentsOf: segmentURL) {
                                    try segData.write(to: segFileURL)
                                }
                                subModifiedLines.append(segFileName)
                            } else {
                                subModifiedLines.append(subLine)
                            }
                        }
                        
                        try subModifiedLines.joined(separator: "\n").write(to: subFileURL, atomically: true, encoding: .utf8)
                        modifiedLines.append(subFileName)
                    }
                } else if !trimmed.hasPrefix("#") && !trimmed.isEmpty {
                    modifiedLines.append(line)
                } else {
                    modifiedLines.append(line)
                }
            }
            
            let masterFileURL = folderURL.appendingPathComponent("master.m3u8")
            try modifiedLines.joined(separator: "\n").write(to: masterFileURL, atomically: true, encoding: .utf8)
            
            let downloadedMovie = DownloadedMovie(
                id: metadata.id,
                title: metadata.title,
                posterPath: metadata.posterPath,
                mediaType: metadata.mediaType,
                season: metadata.season,
                episode: metadata.episode,
                episodeName: metadata.episodeName,
                localURL: masterFileURL.absoluteString,
                originalURL: originalURLString,
                fileSize: 0
            )
            
            DispatchQueue.main.async {
                self.downloadedMovies.removeAll { $0.id == metadata.id && $0.season == metadata.season && $0.episode == metadata.episode }
                self.downloadedMovies.append(downloadedMovie)
                
                self.activeDownloads[key]?.status = .completed
                self.activeDownloads[key]?.progress = 1.0
                self.pendingMetadata.removeValue(forKey: key)
                self.downloadTasks.removeValue(forKey: key)
                
                self.saveDownloadedMovies()
                
                try? fileManager.removeItem(at: tempURL)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.activeDownloads.removeValue(forKey: key)
                }
            }
        } catch {
            DispatchQueue.main.async {
                print("❌ Save error: \(error)")
                self.activeDownloads[key]?.status = .failed
            }
        }
    }
}