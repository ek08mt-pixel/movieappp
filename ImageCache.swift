import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
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
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable().aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.gray.opacity(0.08))
                    .task {
                        guard let url = url else { return }
                        if let cached = ImageCache.shared.get(for: url) {
                            image = cached
                        } else {
                            do {
                                let (data, _) = try await URLSession.shared.data(from: url)
                                if let img = UIImage(data: data) {
                                    ImageCache.shared.set(img, for: url)
                                    image = img
                                }
                            } catch {}
                        }
                    }
            }
        }
    }
}
