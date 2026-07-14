import Foundation
import AVFoundation

class LocalHLSProtocol: URLProtocol {
    static let scheme = "localhls"
    
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == scheme
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "Invalid URL", code: -1))
            return
        }
        
        let fileURL = URL(fileURLWithPath: url.path)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "File not found: \(fileURL.path)", code: -2))
            return
        }
        
        let mime: String = {
            switch fileURL.pathExtension {
            case "m3u8": return "application/vnd.apple.mpegurl"
            case "ts": return "video/mp2t"
            default: return "application/octet-stream"
            }
        }()
        
        let response = URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}