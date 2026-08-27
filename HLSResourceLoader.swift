import Foundation
import AVFoundation

final class HLSResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private let session: URLSession
    private var pendingRequests: [URLRequest: URLSessionDataTask] = [:]
    
    override init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Referer": "https://film4k.net/",
            "Accept": "application/vnd.apple.mpegurl,*/*"
        ]
        session = URLSession(configuration: config)
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else { return false }
        
        // Chuyển scheme proxyhls:// về https://
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.scheme = "https"
        let originalURL = components.url!
        
        var request = URLRequest(url: originalURL)
        request.timeoutInterval = 15
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        request.setValue("application/vnd.apple.mpegurl,*/*", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                loadingRequest.finishLoading(with: error)
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                loadingRequest.finishLoading(with: NSError(domain: "HLS", code: -1))
                return
            }
            
            loadingRequest.contentInformationRequest?.contentType = httpResponse.mimeType
            loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
            loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            
            loadingRequest.dataRequest?.respond(with: data)
            loadingRequest.finishLoading()
            
            self.pendingRequests.removeValue(forKey: request)
        }
        
        pendingRequests[request] = task
        task.resume()
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        let request = loadingRequest.request
        pendingRequests[request]?.cancel()
        pendingRequests.removeValue(forKey: request)
    }
    }