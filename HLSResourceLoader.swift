import Foundation
import AVFoundation

class HLSResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    private let folderURL: URL
    
    init(playlistURL: URL) {
        self.folderURL = playlistURL.deletingLastPathComponent()
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: NSError(domain: "No URL", code: -1))
            return false
        }
        
        let fileName = url.lastPathComponent
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        print("📂 Request: \(fileName)")
        
        if fileName.hasSuffix(".m3u8") {
            return handlePlaylist(fileURL: fileURL, loadingRequest: loadingRequest)
        } else if fileName.hasSuffix(".ts") {
            return handleSegment(fileURL: fileURL, loadingRequest: loadingRequest)
        }
        
        return false
    }
    
    private func handlePlaylist(fileURL: URL, loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard var content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            loadingRequest.finishLoading(with: NSError(domain: "No playlist", code: -2))
            return false
        }
        
        // Sửa relative paths thành custom scheme
        var lines = content.components(separatedBy: .newlines)
        for i in 0..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if !trimmed.hasPrefix("#") && !trimmed.isEmpty {
                if trimmed.hasSuffix(".m3u8") {
                    lines[i] = "hls-custom://\(trimmed)"
                } else if trimmed.hasSuffix(".ts") {
                    lines[i] = "hls-custom://\(trimmed)"
                }
            }
        }
        content = lines.joined(separator: "\n")
        
        let data = content.data(using: .utf8)!
        loadingRequest.contentInformationRequest?.contentType = "application/vnd.apple.mpegurl"
        loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
        loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = false
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
        print("✅ Served playlist: \(fileURL.lastPathComponent)")
        return true
    }
    
    private func handleSegment(fileURL: URL, loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("❌ Segment not found: \(fileURL.lastPathComponent)")
            loadingRequest.finishLoading(with: NSError(domain: "No segment", code: -3))
            return false
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            loadingRequest.contentInformationRequest?.contentType = "video/mp2t"
            loadingRequest.contentInformationRequest?.contentLength = Int64(data.count)
            loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            
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
        } catch {
            print("❌ Failed to read segment: \(error)")
            loadingRequest.finishLoading(with: error)
            return false
        }
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {}
}