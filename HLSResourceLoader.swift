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
        
        // Nếu là file .m3u8, parse và sửa path thành absolute
        if fileName.hasSuffix(".m3u8") {
            if var content = try? String(contentsOf: fileURL, encoding: .utf8) {
                let lines = content.components(separatedBy: .newlines)
                var fixedLines: [String] = []
                
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !trimmed.hasPrefix("#") && !trimmed.isEmpty && (trimmed.hasSuffix(".ts") || trimmed.hasSuffix(".m3u8")) {
                        let absoluteURL = segmentsDir.appendingPathComponent(trimmed)
                        fixedLines.append(absoluteURL.absoluteString)
                    } else {
                        fixedLines.append(line)
                    }
                }
                
                content = fixedLines.joined(separator: "\n")
                let data = content.data(using: .utf8)!
                
                if let contentRequest = loadingRequest.contentInformationRequest {
                    contentRequest.contentType = "application/vnd.apple.mpegurl"
                    contentRequest.contentLength = Int64(data.count)
                    contentRequest.isByteRangeAccessSupported = false
                }
                
                if let dataRequest = loadingRequest.dataRequest {
                    dataRequest.respond(with: data)
                }
                
                loadingRequest.finishLoading()
                return true
            }
        }
        
        // File .ts hoặc file khác
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