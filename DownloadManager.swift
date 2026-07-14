import Foundation

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

class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()
    @Published var downloads: [DownloadItem] = []
    @Published var progress: [String: Double] = [:]
    
    private var session: URLSession!
    private var tasks: [String: URLSessionDownloadTask] = [:]
    private var resumeData: [String: Data] = [:]
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.emmew.downloads")
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
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
        
        let task = session.downloadTask(with: url)
        task.taskDescription = id
        tasks[id] = task
        task.resume()
    }
    
    func pause(_ id: String) {
        tasks[id]?.cancel { data in
            if let data = data { self.resumeData[id] = data }
        }
        tasks[id] = nil
        updateStatus(id, .paused)
    }
    
    func resume(_ id: String) {
        guard let data = resumeData[id], let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        let task = session.downloadTask(withResumeData: data)
        task.taskDescription = id
        tasks[id] = task
        downloads[idx].status = .downloading
        task.resume()
        resumeData[id] = nil
    }
    
    func delete(_ id: String) {
        tasks[id]?.cancel()
        tasks[id] = nil
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
            UserDefaults.standard.set(data, forKey: "downloaded_items_v1")
        }
    }
    
    private func loadDownloads() {
        if let data = UserDefaults.standard.data(forKey: "downloaded_items_v1"),
           let items = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            downloads = items
            for i in 0..<downloads.count where downloads[i].status == .downloading {
                downloads[i].status = .paused
            }
        }
    }
    
    // MARK: - Delegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let id = downloadTask.taskDescription,
              let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dlDir = docs.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dlDir, withIntermediateDirectories: true)
        
        let dest = dlDir.appendingPathComponent("\(id).mp4")
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
        tasks[id] = nil
        save()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let id = downloadTask.taskDescription,
              let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        
        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        downloads[idx].progress = p
        downloads[idx].downloadedSize = totalBytesWritten
        downloads[idx].fileSize = totalBytesExpectedToWrite
        progress[id] = p
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