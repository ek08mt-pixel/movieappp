import Foundation
import AVFoundation

class HLSResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    private let playlistURL: URL
    private let segmentsDir: URL
    
    init(playlistURL: URL) {
        self.playlistURL = playlistURL
        self.segmentsDir = playlistURL.deletingLastPathComponent()
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: NSError(domain: "No URL", code: -1))
            return false
        }
        
        let fileName = url.lastPathComponent
        let fileURL = segmentsDir.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            loadingRequest.finishLoading(with: NSError(domain: "File not found: \(fileName)", code: -2))
            return false
        }
        
        let mimeType: String = {
            switch fileURL.pathExtension {
            case "m3u8": return "application/vnd.apple.mpegurl"
            case "ts": return "video/mp2t"
            default: return "application/octet-stream"
            }
        }()
        
        if let contentRequest = loadingRequest.contentInformationRequest {
            contentRequest.contentType = mimeType
            contentRequest.contentLength = Int64(data.count)
            contentRequest.isByteRangeAccessSupported = false
        }
        
        if let dataRequest = loadingRequest.dataRequest {
            let start = Int(dataRequest.requestedOffset)
            let length = dataRequest.requestedLength
            let end = min(start + length, data.count)
            if start < data.count {
                dataRequest.respond(with: data.subdata(in: start..<end))
            }
        }
        
        loadingRequest.finishLoading()
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {}
}