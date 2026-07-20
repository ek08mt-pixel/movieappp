import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    private var runningRequests: Set<String> = []
    private let lock = NSLock()
    let session: URLSession
    
    init() {
        cache.countLimit = 400
        cache.totalCostLimit = 100 * 1024 * 1024
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 5
        config.timeoutIntervalForRequest = 5
        config.httpMaximumConnectionsPerHost = 4
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }
    
    func get(for url: URL, size: String = "thumb") -> UIImage? {
        return cache.object(forKey: "\(size)_\(url.absoluteString)" as NSString)
    }
    
    func set(_ image: UIImage, for url: URL, size: String = "thumb") {
        let key = "\(size)_\(url.absoluteString)" as NSString
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key, cost: cost)
    }
    
    func isRunning(_ key: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return runningRequests.contains(key)
    }
    
    func markRunning(_ key: String) {
        lock.lock(); defer { lock.unlock() }
        runningRequests.insert(key)
    }
    
    func unmarkRunning(_ key: String) {
        lock.lock(); defer { lock.unlock() }
        runningRequests.remove(key)
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    var size: ImageSize = .thumb
    
    enum ImageSize {
        case thumb
        case backdrop
        case detail
        
        var targetSize: CGSize {
            switch self {
            case .thumb: return CGSize(width: 150, height: 225)
            case .backdrop: return CGSize(width: 500, height: 281)
            case .detail: return CGSize(width: 300, height: 450)
            }
        }
        
        var key: String {
            switch self {
            case .thumb: return "thumb"
            case .backdrop: return "backdrop"
            case .detail: return "detail"
            }
        }
    }
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(white: 0.12))
                    .task {
                        guard let url = url else { return }
                        let key = "\(size.key)_\(url.absoluteString)"
                        
                        if ImageCache.shared.isRunning(key) { return }
                        
                        if let cached = ImageCache.shared.get(for: url, size: size.key) {
                            await MainActor.run { image = cached }
                            return
                        }
                        
                        ImageCache.shared.markRunning(key)
                        
                        if let img = await loadAndResize(url: url, targetSize: size.targetSize) {
                            await MainActor.run { image = img }
                        }
                        
                        ImageCache.shared.unmarkRunning(key)
                    }
            }
        }
    }
    
    private func loadAndResize(url: URL, targetSize: CGSize) async -> UIImage? {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 5)
        request.setValue("image/jpeg,image/png,image/webp", forHTTPHeaderField: "Accept")
        
        guard let (data, _) = try? await ImageCache.shared.session.data(for: request),
              let img = UIImage(data: data) else { return nil }
        
        let resized = img.resized(to: targetSize)
        ImageCache.shared.set(resized, for: url, size: size.key)
        return resized
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let scale = min(size.width / self.size.width, size.height / self.size.height)
        let newSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
} 