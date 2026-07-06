import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    init() {
        cache.countLimit = 300
        cache.totalCostLimit = 100 * 1024 * 1024
    }
    
    func get(for url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
    
    func set(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url.absoluteString as NSString)
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable().aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.08)], startPoint: .top, endPoint: .bottom))
                    .task {
                        guard let url = url, !isLoading else { return }
                        isLoading = true
                        if let cached = ImageCache.shared.get(for: url) {
                            await MainActor.run { image = cached }
                        } else {
                            do {
                                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
                                let (data, _) = try await URLSession.shared.data(for: request)
                                if let img = UIImage(data: data) {
                                    let resized = img.resized(to: CGSize(width: 400, height: 600))
                                    ImageCache.shared.set(resized, for: url)
                                    await MainActor.run { image = resized }
                                }
                            } catch {}
                        }
                        isLoading = false
                    }
            }
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}