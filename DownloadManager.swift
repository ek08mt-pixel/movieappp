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
        let id: Int; let title: String; let posterPath: String?
        let mediaType: String?; let season: Int?; let episode: Int?; let episodeName: String?
    }
    
    struct DownloadedMovie: Codable, Identifiable {
        let id: Int; let title: String; let posterPath: String?
        let mediaType: String?; let season: Int?; let episode: Int?
        let episodeName: String?; let localURL: String; let originalURL: String; let fileSize: Int64
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
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
        guard activeDownloads[key] == nil || activeDownloads[key]?.status == .failed else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://phimapi.com", forHTTPHeaderField: "Referer")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        
        let task = downloadSession.dataTask(with: request)
        task.resume()
        downloadTasks[key] = task
        
        pendingMetadata[key] = PendingDownloadMetadata(id: movieId, title: title, posterPath: posterPath, mediaType: mediaType, season: season, episode: episode, episodeName: episodeName)
        activeDownloads[key] = DownloadInfo(progress: 0, status: .downloading)
    }
    
    func pauseDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
        downloadTasks[key]?.cancel()
        downloadTasks.removeValue(forKey: key)
        activeDownloads[key]?.status = .paused
    }
    
    func resumeDownload(movieId: Int, season: Int?, episode: Int?) {
        activeDownloads["\(movieId)_S\(season ?? 0)E\(episode ?? 0)"]?.status = .waiting
    }
    
    func cancelDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = "\(movieId)_S\(season ?? 0)E\(episode ?? 0)"
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
        if let url = getLocalURL(movieId: movieId, season: season, episode: episode) {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
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

// MARK: - URLSessionDataDelegate
extension DownloadManager: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let key = downloadTasks.first(where: { $0.value == dataTask })?.key else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(key).m3u8")
        if FileManager.default.fileExists(atPath: tempURL.path) {
            if let fh = try? FileHandle(forWritingTo: tempURL) { fh.seekToEndOfFile(); fh.write(data); fh.closeFile() }
        } else { try? data.write(to: tempURL) }
        if let d = try? Data(contentsOf: tempURL) { activeDownloads[key]?.progress = min(Double(d.count) / 10000.0, 0.29) }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError?, error.code != NSURLErrorCancelled {
            if let key = downloadTasks.first(where: { $0.value == task })?.key { activeDownloads[key]?.status = .failed }
            return
        }
        
        guard let key = downloadTasks.first(where: { $0.value == task })?.key,
              let meta = pendingMetadata[key] else { return }
        
        activeDownloads[key]?.progress = 0.3
        let originalURLString = task.originalRequest?.url?.absoluteString ?? ""
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(key).m3u8")
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderName = UUID().uuidString
        let folderURL = documentsPath.appendingPathComponent(folderName)
        
        DispatchQueue.global(qos: .background).async {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                
                let content = try String(contentsOf: tempURL, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                
                var totalSegments = 0
                var downloadedSegments = 0
                var subPlaylistName = "sub.m3u8"
                
                // Tìm sub-playlist
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !trimmed.hasPrefix("#") && !trimmed.isEmpty && trimmed.hasSuffix(".m3u8") {
                        subPlaylistName = trimmed.hasPrefix("http") ? "sub.m3u8" : trimmed
                        let subURL: URL
                        if trimmed.hasPrefix("http") {
                            subURL = URL(string: trimmed)!
                        } else if let origURL = URL(string: originalURLString) {
                            subURL = origURL.deletingLastPathComponent().appendingPathComponent(trimmed)
                        } else { continue }
                        
                        if let subData = try? Data(contentsOf: subURL),
                           let subContent = String(data: subData, encoding: .utf8) {
                            for subLine in subContent.components(separatedBy: .newlines) {
                                let subTrimmed = subLine.trimmingCharacters(in: .whitespaces)
                                if !subTrimmed.hasPrefix("#") && !subTrimmed.isEmpty && subTrimmed.hasSuffix(".ts") {
                                    totalSegments += 1
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async { self.activeDownloads[key]?.progress = 0.4 }
                
                // Tải segment và ghi playlist với relative path
                var masterLines: [String] = []
                
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !trimmed.hasPrefix("#") && !trimmed.isEmpty && trimmed.hasSuffix(".m3u8") {
                        let subURL: URL
                        if trimmed.hasPrefix("http") {
                            subURL = URL(string: trimmed)!
                        } else if let origURL = URL(string: originalURLString) {
                            subURL = origURL.deletingLastPathComponent().appendingPathComponent(trimmed)
                        } else { masterLines.append(line); continue }
                        
                        if let subData = try? Data(contentsOf: subURL),
                           let subContent = String(data: subData, encoding: .utf8) {
                            let subLines = subContent.components(separatedBy: .newlines)
                            var relativeSubLines: [String] = []
                            let baseSubURL = subURL.deletingLastPathComponent()
                            
                            for subLine in subLines {
                                let subTrimmed = subLine.trimmingCharacters(in: .whitespaces)
                                if !subTrimmed.hasPrefix("#") && !subTrimmed.isEmpty && subTrimmed.hasSuffix(".ts") {
                                    let segURL: URL
                                    if subTrimmed.hasPrefix("http") {
                                        segURL = URL(string: subTrimmed)!
                                    } else {
                                        segURL = baseSubURL.appendingPathComponent(subTrimmed)
                                    }
                                    let segFileName = segURL.lastPathComponent
                                    let segFileURL = folderURL.appendingPathComponent(segFileName)
                                    if let segData = try? Data(contentsOf: segURL) {
                                        try segData.write(to: segFileURL)
                                    }
                                    relativeSubLines.append(segFileName)  // CHỈ tên file, relative
                                    downloadedSegments += 1
                                    let progress = 0.4 + (0.6 * Double(downloadedSegments) / Double(max(totalSegments, 1)))
                                    DispatchQueue.main.async { self.activeDownloads[key]?.progress = min(progress, 0.99) }
                                } else {
                                    relativeSubLines.append(subLine)
                                }
                            }
                            
                            let subFileURL = folderURL.appendingPathComponent("sub.m3u8")
var finalContent = relativeSubLines.joined(separator: "\n")
if !finalContent.contains("#EXT-X-ENDLIST") {
    finalContent += "\n#EXT-X-ENDLIST"
}
try finalContent.write(to: subFileURL, atomically: true, encoding: .utf8)
masterLines.append("sub.m3u8")  // relative
                        }
                    } else {
                        masterLines.append(line)
                    }
                }
                
                // Ghi master.m3u8
                let masterFileURL = folderURL.appendingPathComponent("master.m3u8")
                try masterLines.joined(separator: "\n").write(to: masterFileURL, atomically: true, encoding: .utf8)
                
                let movie = DownloadedMovie(id: meta.id, title: meta.title, posterPath: meta.posterPath, mediaType: meta.mediaType, season: meta.season, episode: meta.episode, episodeName: meta.episodeName, localURL: masterFileURL.absoluteString, originalURL: originalURLString, fileSize: 0)
                
                DispatchQueue.main.async {
                    self.downloadedMovies.removeAll { $0.id == meta.id && $0.season == meta.season && $0.episode == meta.episode }
                    self.downloadedMovies.append(movie)
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
                DispatchQueue.main.async { self.activeDownloads[key]?.status = .failed }
            }
        }
    }
}