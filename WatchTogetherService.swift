import Foundation

class WatchTogetherService: ObservableObject {
    static let shared = WatchTogetherService()
    
    private let baseURL = "https://emmew-d71a8-default-rtdb.firebaseio.com"
    private var roomCode: String = ""
    var userId: String = ""
    private var userName: String = ""
    private var timer: Timer?
    private var leaveTimer: Timer?
    
    @Published var isInRoom = false
    @Published var isHost = false
    @Published var currentRoomCode = ""
    @Published var currentRoomName = ""
    @Published var messages: [ChatMessage] = []
    @Published var participants: [Participant] = []
    @Published var remoteState: RemotePlaybackState?
    
    @Published var pendingRoomCode: String = ""
    @Published var pendingRoomName: String = ""
    @Published var pendingRoomMovie: String = ""
    @Published var pendingLeaveSeconds: Int = 300
    @Published var hasPendingRoom: Bool = false
    
    var currentUserId: String { userId }
    
    static let defaultAvatars = ["🐱","🐶","🐰","🐻","🐼","🐨","🐯","🦊","🐸","🐵","🐮","🐷","🐹","🐭","🦄","🐙"]
    
    var userAvatar: String {
        if let p = participants.first(where: { $0.userId == userId }) {
            return p.avatar
        }
        return WatchTogetherService.defaultAvatars[abs(userId.hashValue) % WatchTogetherService.defaultAvatars.count]
    }
    
    struct ChatMessage: Codable, Identifiable {
        var id: String { "\(timestamp)_\(userId)" }
        let userId: String
        let userName: String
        let avatar: String
        let text: String
        let timestamp: Double
    }
    
    struct Participant: Codable {
        let userId: String
        let userName: String
        var avatar: String
        var isOnline: Bool
    }
    
    struct RemotePlaybackState: Codable {
        let action: String
        let time: Double
        let timestamp: Double
        let episodeNumber: Int?
        let seasonNumber: Int?
    }
    
    func createRoom(roomName: String, userName: String, completion: @escaping (String) -> Void) {
        self.userName = userName
        self.userId = UUID().uuidString
        self.isHost = true
        
        let code = String(format: "%06d", Int.random(in: 0...999999))
        self.roomCode = code
        self.currentRoomCode = code
        self.currentRoomName = roomName
        
        let avatar = WatchTogetherService.defaultAvatars[abs(userId.hashValue) % WatchTogetherService.defaultAvatars.count]
        
        let roomData: [String: Any] = [
            "code": code,
            "roomName": roomName,
            "hostId": userId,
            "hostName": userName,
            "createdAt": Date().timeIntervalSince1970,
            "participants": [
                userId: ["userId": userId, "userName": userName, "avatar": avatar, "isOnline": true]
            ]
        ]
        
        put(path: "rooms/\(code)/info", data: roomData) { _ in
            DispatchQueue.main.async {
                self.isInRoom = true
                self.hasPendingRoom = false
                self.startListening()
                completion(code)
            }
        }
    }
    
    func joinRoom(code: String, userName: String, completion: @escaping (Bool, String?) -> Void) {
        self.userName = userName
        self.userId = UUID().uuidString
        self.roomCode = code
        self.isHost = false
        
        get(path: "rooms/\(code)/info") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data, data["code"] != nil else {
                DispatchQueue.main.async { completion(false, nil) }
                return
            }
            
            let roomName = data["roomName"] as? String ?? ""
            let avatar = WatchTogetherService.defaultAvatars[abs(self.userId.hashValue) % WatchTogetherService.defaultAvatars.count]
            
            let participant: [String: Any] = ["userId": self.userId, "userName": self.userName, "avatar": avatar, "isOnline": true]
            self.put(path: "rooms/\(code)/info/participants/\(self.userId)", data: participant) { _ in
                DispatchQueue.main.async {
                    self.currentRoomCode = code
                    self.currentRoomName = roomName
                    self.isInRoom = true
                    self.hasPendingRoom = false
                    self.startListening()
                    completion(true, roomName)
                }
            }
        }
    }
    
    // Chuẩn bị rời phòng - lưu pending, không đụng gì đến state khác
    func prepareToLeave(movieTitle: String, code: String, name: String) {
        leaveTimer?.invalidate()
        timer?.invalidate()
        timer = nil
        
        pendingRoomCode = code
        pendingRoomName = name
        pendingRoomMovie = movieTitle
        pendingLeaveSeconds = 300
        hasPendingRoom = true
        
        // Đánh dấu offline
        put(path: "rooms/\(code)/info/participants/\(userId)/isOnline", data: false)
        
        // Countdown
        leaveTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.pendingLeaveSeconds > 0 {
                    self.pendingLeaveSeconds -= 1
                } else {
                    self.leaveTimer?.invalidate()
                    self.hasPendingRoom = false
                    self.delete(path: "rooms/\(self.pendingRoomCode)/info/participants/\(self.userId)") { _ in }
                    self.pendingRoomCode = ""
                    self.roomCode = ""
                    self.userId = ""
                }
            }
        }
    }
    
    // Gọi sau khi View đã về lobby an toàn
    func didReturnToLobby() {
        isInRoom = false
        currentRoomCode = ""
        currentRoomName = ""
        messages = []
        participants = []
    }
    
    func rejoinPendingRoom(completion: @escaping (Bool) -> Void) {
        guard hasPendingRoom, !pendingRoomCode.isEmpty else {
            completion(false)
            return
        }
        
        leaveTimer?.invalidate()
        roomCode = pendingRoomCode
        currentRoomCode = pendingRoomCode
        currentRoomName = pendingRoomName
        isInRoom = true
        hasPendingRoom = false
        
        put(path: "rooms/\(roomCode)/info/participants/\(userId)/isOnline", data: true) { _ in
            DispatchQueue.main.async {
                self.startListening()
                completion(true)
            }
        }
    }
    
    func leaveRoom() {
        leaveTimer?.invalidate()
        timer?.invalidate()
        timer = nil
        delete(path: "rooms/\(roomCode)/info/participants/\(userId)") { _ in }
        isInRoom = false
        isHost = false
        currentRoomCode = ""
        currentRoomName = ""
        messages = []
        participants = []
        roomCode = ""
        userId = ""
        hasPendingRoom = false
        pendingRoomCode = ""
    }
    
    func sendPlaybackState(action: String, time: Double) {
        let state: [String: Any] = [
            "action": action,
            "time": time,
            "timestamp": Date().timeIntervalSince1970
        ]
        put(path: "rooms/\(roomCode)/playback", data: state)
    }
    
    func sendMessage(text: String) {
        let avatar = userAvatar
        let msg = ChatMessage(userId: userId, userName: userName, avatar: avatar, text: text, timestamp: Date().timeIntervalSince1970)
        if let data = try? JSONEncoder().encode(msg),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let msgId = "\(Int(msg.timestamp * 1000))"
            put(path: "rooms/\(roomCode)/messages/\(msgId)", data: dict)
        }
    }
    
    private func startListening() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchUpdates()
        }
    }
    
    private func fetchUpdates() {
        guard !roomCode.isEmpty else { return }
        
        get(path: "rooms/\(roomCode)/playback") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data,
                  let action = data["action"] as? String,
                  let time = data["time"] as? Double else { return }
            DispatchQueue.main.async {
                self.remoteState = RemotePlaybackState(action: action, time: time, timestamp: data["timestamp"] as? Double ?? 0, episodeNumber: data["episodeNumber"] as? Int, seasonNumber: data["seasonNumber"] as? Int)
            }
        }
        
        get(path: "rooms/\(roomCode)/messages") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data else { return }
            let sorted = data.compactMap { _, value -> ChatMessage? in
                guard let dict = value as? [String: Any],
                      let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                      let msg = try? JSONDecoder().decode(ChatMessage.self, from: jsonData) else { return nil }
                return msg
            }.sorted { $0.timestamp < $1.timestamp }
            
            DispatchQueue.main.async {
                self.messages = Array(sorted.suffix(50))
            }
        }
        
        get(path: "rooms/\(roomCode)/info") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data else { return }
            if let roomName = data["roomName"] as? String {
                DispatchQueue.main.async { self.currentRoomName = roomName }
            }
        }
        
        get(path: "rooms/\(roomCode)/info/participants") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data else { return }
            let parts = data.compactMap { _, value -> Participant? in
                guard let dict = value as? [String: Any],
                      let userId = dict["userId"] as? String,
                      let userName = dict["userName"] as? String else { return nil }
                return Participant(userId: userId, userName: userName, avatar: dict["avatar"] as? String ?? "🐱", isOnline: dict["isOnline"] as? Bool ?? true)
            }
            DispatchQueue.main.async {
                self.participants = parts
            }
        }
    }
    
    private func get<T>(path: String, completion: @escaping (T?) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(path).json") else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? T else { completion(nil); return }
            completion(json)
        }.resume()
    }
    
    private func put(path: String, data: Any, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(baseURL)/\(path).json"),
              let body = try? JSONSerialization.data(withJSONObject: data) else { completion?(false); return }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: req) { _, response, _ in
            completion?((response as? HTTPURLResponse)?.statusCode == 200)
        }.resume()
    }
    
    private func delete(path: String, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(baseURL)/\(path).json") else { completion?(false); return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: req) { _, response, _ in
            completion?((response as? HTTPURLResponse)?.statusCode == 200)
        }.resume()
    }
}