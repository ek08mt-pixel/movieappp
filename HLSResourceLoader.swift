import Foundation
import AVFoundation

final class HLSResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    static let shared = HLSResourceLoader()
    
    private let session: URLSession
    
    override private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Referer": "https://film4k.net/",
            "Origin": "https://film4k.net",
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "application/vnd.apple.mpegurl,*/*"
        ]
        session = URLSession(configuration: config)
        super.init()
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        
        guard let url = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: NSError(domain: "HLS", code: 1))
            return false
        }
        
        // Chuyển scheme custom-hls:// sang https://
        var realURLString = url.absoluteString
        if realURLString.hasPrefix("custom-hls://") {
            realURLString = String(realURLString.dropFirst("custom-hls://".count))
        }
        
        guard let realURL = URL(string: realURLString) else {
            loadingRequest.finishLoading(with: NSError(domain: "HLS", code: 2))
            return false
        }
        
        var request = URLRequest(url: realURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        request.setValue("https://film4k.net", forHTTPHeaderField: "Origin")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("application/vnd.apple.mpegurl,*/*", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                loadingRequest.finishLoading(with: error)
                return
            }
            
            if let response = response {
                loadingRequest.response = response
            }
            
            if let data = data {
                loadingRequest.dataRequest?.respond(with: data)
            }
            
            loadingRequest.finishLoading()
        }
        task.resume()
        
        return true
    }
}