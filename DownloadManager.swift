import Foundation
import AVFoundation

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadInfo] = [:]
    @Published var downloadedMovies: [DownloadedMovie] = []
    
    private var downloadSession: URLSession!
    private let backgroundIdentifier = "com.emmew.backgroundDownload"
    private let downloadedKey = "downloadedMovies"
    
    private var pendingMetadata: [String: PendingDownloadMetadata] = [:]
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var downloadResumeData: [String: Data] = [:]
    
    struct DownloadInfo {
        var progress: Double = 0
        var status: DownloadStatus = .waiting
        var task: URLSessionDownloadTask?
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
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        downloadSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        loadDownloadedMovies()
        restorePendingDownloads()
    }
    
    func startDownload(url: URL, movieId: Int, title: String, posterPath: String?, mediaType: String?, season: Int? = nil, episode: Int? = nil, episodeName: String? = nil) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        
        guard activeDownloads[key] == nil || activeDownloads[key]?.status == .failed else { return }
        
        let task = downloadSession.downloadTask(with: url)
        task.resume()
        
        downloadTasks[key] = task
        
        pendingMetadata[key] = PendingDownloadMetadata(
            id: movieId,
            title: title,
            posterPath: posterPath,
            mediaType: mediaType,
            season: season,
            episode: episode,
            episodeName: episodeName
        )
        
        activeDownloads[key] = DownloadInfo(progress: 0, status: .downloading, task: task)
    }
    
    func pauseDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        guard let task = downloadTasks[key] else { return }
        task.cancel { resumeData in
            self.downloadResumeData[key] = resumeData
            self.activeDownloads[key]?.status = .paused
        }
    }
    
    func resumeDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        guard let resumeData = downloadResumeData[key] else { return }
        let task = downloadSession.downloadTask(withResumeData: resumeData)
        task.resume()
        downloadTasks[key] = task
        activeDownloads[key]?.status = .downloading
    }
    
    func cancelDownload(movieId: Int, season: Int?, episode: Int?) {
        let key = downloadKey(movieId: movieId, season: season, episode: episode)
        downloadTasks[key]?.cancel()
        downloadTasks.removeValue(forKey: key)
        downloadResumeData.removeValue(forKey: key)
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
                if let downloadTask = task as? URLSessionDownloadTask {
                    downloadTask.resume()
                }
            }
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = downloadTask.originalRequest?.url?.lastPathComponent ?? UUID().uuidString + ".mp4"
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)
            
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            if let key = findKey(for: downloadTask),
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
            }
        } catch {
            print("Failed to save: \(error)")
            if let key = findKey(for: downloadTask) {
                activeDownloads[key]?.status = .failed
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        if let key = findKey(for: downloadTask) {
            activeDownloads[key]?.progress = min(progress, 1.0)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError? {
            if error.code == NSURLErrorCancelled {
                return
            }
            if let downloadTask = task as? URLSessionDownloadTask,
               let key = findKey(for: downloadTask) {
                activeDownloads[key]?.status = .failed
            }
        }
    }
    
    private func findKey(for task: URLSessionDownloadTask) -> String? {
        return downloadTasks.first(where: { $0.value == task })?.key
    }
}