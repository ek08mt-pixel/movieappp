import Foundation
import Network

final class LocalHTTPServer {
    static let shared = LocalHTTPServer()
    private var listener: NWListener?
    private var baseDirectory: URL?
    private var isRunning = false
    
    func start(baseDirectory: URL, port: UInt16 = 8080) -> Bool {
        self.baseDirectory = baseDirectory
        let params = NWParameters.tcp
        do {
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            listener?.newConnectionHandler = { connection in
                connection.start(queue: .global())
                self.receive(on: connection)
            }
            listener?.start(queue: .global())
            isRunning = true
            print("🌐 Server started on port \(port)")
            return true
        } catch {
            print("❌ Server failed: \(error)")
            return false
        }
    }
    
    func stop() {
        listener?.cancel()
        isRunning = false
    }
    
    var serverURL: URL? {
        URL(string: "http://127.0.0.1:8080")
    }
    
    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self = self, let data = data,
                  let requestString = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            self.handleRequest(requestString, on: connection)
        }
    }
    
    private func handleRequest(_ request: String, on connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first, firstLine.contains("GET ") else {
            sendError(connection, status: "400 Bad Request")
            return
        }
        
        let components = firstLine.components(separatedBy: " ")
        guard components.count >= 2 else {
            sendError(connection, status: "400 Bad Request")
            return
        }
        
        let path = components[1].removingPercentEncoding ?? components[1]
        let fileName = path == "/" ? "sub.m3u8" : String(path.dropFirst())
        
        guard let baseDir = baseDirectory else {
            sendError(connection, status: "500 Internal Server Error")
            return
        }
        
        let fileURL = baseDir.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            sendError(connection, status: "404 Not Found")
            return
        }
        
        guard let fileData = try? Data(contentsOf: fileURL) else {
            sendError(connection, status: "500 Internal Server Error")
            return
        }
        
        let mimeType = fileName.hasSuffix(".m3u8") ? "application/vnd.apple.mpegurl" : "video/mp2t"
        
        // Xử lý Range request
        if let rangeLine = lines.first(where: { $0.hasPrefix("Range: bytes=") }) {
            let rangeString = rangeLine.replacingOccurrences(of: "Range: bytes=", with: "")
            let parts = rangeString.components(separatedBy: "-")
            if let start = Int(parts[0]) {
                let end = parts.count > 1 ? (Int(parts[1]) ?? fileData.count - 1) : fileData.count - 1
                let length = min(end - start + 1, fileData.count - start)
                let subData = fileData.subdata(in: start..<start + length)
                
                let responseHeaders = """
                HTTP/1.1 206 Partial Content\r
                Content-Type: \(mimeType)\r
                Content-Length: \(subData.count)\r
                Content-Range: bytes \(start)-\(start + subData.count - 1)/\(fileData.count)\r
                Accept-Ranges: bytes\r
                Connection: close\r
                \r
                """
                connection.send(content: responseHeaders.data(using: .utf8), completion: .idempotent)
                connection.send(content: subData, completion: .idempotent)
                connection.cancel()
                return
            }
        }
        
        // Full response
        let responseHeaders = """
        HTTP/1.1 200 OK\r
        Content-Type: \(mimeType)\r
        Content-Length: \(fileData.count)\r
        Accept-Ranges: bytes\r
        Connection: close\r
        \r
        """
        connection.send(content: responseHeaders.data(using: .utf8), completion: .idempotent)
        connection.send(content: fileData, completion: .idempotent)
        connection.cancel()
    }
    
    private func sendError(_ connection: NWConnection, status: String) {
        let body = status
        let response = """
        HTTP/1.1 \(status)\r
        Content-Length: \(body.count)\r
        Connection: close\r
        \r
        \(body)
        """
        connection.send(content: response.data(using: .utf8), completion: .idempotent)
        connection.cancel()
    }
}