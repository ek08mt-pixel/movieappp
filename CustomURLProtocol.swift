import Foundation

final class CustomURLProtocol: URLProtocol {
    private var dataTask: URLSessionDataTask?
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Referer": "https://film4k.net/",
            "Accept": "application/vnd.apple.mpegurl,*/*",
            "Connection": "keep-alive"
        ]
        return URLSession(configuration: config)
    }()
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let host = request.url?.host else { return false }
        return host.contains("film4k.net") || host.contains("phim1280.tv")
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        var mutableRequest = request
        mutableRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        mutableRequest.setValue("https://film4k.net/", forHTTPHeaderField: "Referer")
        mutableRequest.setValue("application/vnd.apple.mpegurl,*/*", forHTTPHeaderField: "Accept")
        return mutableRequest
    }
    
    override func startLoading() {
        guard let request = self.request as? URLRequest else { return }
        
        dataTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            
            self.client?.urlProtocolDidFinishLoading(self)
        }
        dataTask?.resume()
    }
    
    override func stopLoading() {
        dataTask?.cancel()
    }
}