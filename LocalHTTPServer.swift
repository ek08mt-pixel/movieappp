 import Foundation
import Network

class LocalHTTPServer {
    static let shared = LocalHTTPServer()
    private var listener: NWListener?
    private var basePath: String = ""
    var port: UInt16 = 0
    
    func start(basePath: String) -> Bool {
        self.basePath = basePath
        
        let queue = DispatchQueue(label: "httpserver")
        let listener = try? NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: 0)!)
        guard let listener = listener else { return false }
        
        listener.newConnectionHandler = { connection in
            connection.start(queue: queue)
            self.handleConnection(connection)
        }
        
        listener.start(queue: queue)
        
        if let port = listener.port?.rawValue {
            self.port = port
            self.listener = listener
            print("🌐 Server started on port \(port)")
            return true
        }
        return false
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
    }
    
    var serverURL: URL? {
        return URL(string: "http://127.0.0.1:\(port)")
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self = self, let data = data,
                  let request = String(data: data, encoding: .utf8) else { connection.cancel(); return }
            
            let lines = request.components(separatedBy: "\r\n")
            let firstLine = lines.first ?? ""
            let parts = firstLine.components(separatedBy: " ")
            guard parts.count >= 2 else { connection.cancel(); return }
            
            let path = parts[1]
            let filePath: String
            
            if path == "/" || path.contains("master.m3u8") {
                filePath = self.basePath + "/master.m3u8"
            } else if path.contains("sub.m3u8") {
                filePath = self.basePath + "/sub.m3u8"
            } else {
                let fileName = (path as NSString).lastPathComponent
                filePath = self.basePath + "/" + fileName
            }
            
            guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                let response = "HTTP/1.1 404 Not Found\r\n\r\n"
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in connection.cancel() }))
                return
            }
            
            let mimeType = filePath.hasSuffix(".m3u8") ? "application/vnd.apple.mpegurl" : "video/mp2t"
            let header = "HTTP/1.1 200 OK\r\nContent-Type: \(mimeType)\r\nContent-Length: \(fileData.count)\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
            
            connection.send(content: header.data(using: .utf8), completion: .contentProcessed({ _ in }))
            connection.send(content: fileData, completion: .contentProcessed({ _ in connection.cancel() }))
        }
    }
}