import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    private var runningRequests: Set<String> = []
    private let lock = NSLock()
    
    init() {
        cache.countLimit = 300
        cache.totalCostLimit = 80 * 1024 * 1024
    }
    
    func get(for url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
    
    func set(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
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
    @State private var image: UIImage?
    @State private var task: Task<Void, Never>?
    
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
                        let key = url.absoluteString
                        
                        if ImageCache.shared.isRunning(key) { return }
                        
                        if let cached = ImageCache.shared.get(for: url) {
                            await MainActor.run { image = cached }
                            return
                        }
                        
                        ImageCache.shared.markRunning(key)
                        
                        let width = UIScreen.main.bounds.width / 3
                        let targetSize = CGSize(width: width, height: width * 1.5)
                        
                        if let img = await loadAndResize(url: url, targetSize: targetSize) {
                            await MainActor.run { image = img }
                        }
                        
                        ImageCache.shared.unmarkRunning(key)
                    }
                    .onDisappear {
                        task?.cancel()
                    }
            }
        }
    }
    
    private func loadAndResize(url: URL, targetSize: CGSize) async -> UIImage? {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8)
        request.setValue("image/jpeg,image/png,image/webp", forHTTPHeaderField: "Accept")
        
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let img = UIImage(data: data) else { return nil }
        
        let resized = img.resized(to: targetSize)
        ImageCache.shared.set(resized, for: url)
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