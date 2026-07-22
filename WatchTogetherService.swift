import Foundation

class WatchTogetherService: ObservableObject {
    static let shared = WatchTogetherService()
    
    private let baseURL = "https://emmew-d71a8-default-rtdb.firebaseio.com"
    private var roomCode: String = ""
    var userId: String = ""
    private var userName: String = ""
    var avatarBase64: String = ""
    private var timer: Timer?
    
    @Published var isInRoom = false
    @Published var isHost = false
    @Published var currentRoomCode = ""
    @Published var currentRoomName = ""
    @Published var messages: [ChatMessage] = []
    @Published var participants: [Participant] = []
    @Published var remoteState: RemotePlaybackState?
    
    var currentUserId: String { userId }
    
    static let defaultAvatars = ["🐱","🐶","🐰","🐻","🐼","🐨","🐯","🦊","🐸","🐵","🐮","🐷","🐹","🐭","🦄","🐙"]
    
    var userAvatar: String {
        if let p = participants.first(where: { $0.userId == userId }) { return p.avatar }
        return WatchTogetherService.defaultAvatars[abs(userId.hashValue) % WatchTogetherService.defaultAvatars.count]
    }
    
    struct ChatMessage: Codable, Identifiable {
    var id: String { "\(timestamp)_\(userId)" }
    let userId: String; let userName: String; let avatar: String; let text: String; let timestamp: Double
    let avatarBase64: String?
}
    
    struct Participant: Codable {
    let userId: String; let userName: String; var avatar: String; var isOnline: Bool
    let avatarBase64: String?
}
    
    struct RemotePlaybackState: Codable {
        let action: String; let time: Double; let timestamp: Double; let episodeNumber: Int?; let seasonNumber: Int?
    }
    
    func createRoom(roomName: String, userName: String, avatar: String? = nil, avatarBase64: String? = nil, completion: @escaping (String) -> Void) {
    self.userName = userName; self.userId = UUID().uuidString; self.isHost = true
    self.avatarBase64 = avatarBase64 ?? ""
    let code = String(format: "%06d", Int.random(in: 0...999999))
    self.roomCode = code; self.currentRoomCode = code; self.currentRoomName = roomName
    let av = avatar ?? WatchTogetherService.defaultAvatars[abs(userId.hashValue) % WatchTogetherService.defaultAvatars.count]
    let roomData: [String: Any] = [
        "code": code, "roomName": roomName, "hostId": userId, "hostName": userName,
        "createdAt": Date().timeIntervalSince1970,
        "participants": [userId: ["userId": userId, "userName": userName, "avatar": av, "avatarBase64": avatarBase64 ?? "", "isOnline": true]]
    ]
    put(path: "rooms/\(code)/info", data: roomData) { _ in
        DispatchQueue.main.async { self.isInRoom = true; self.startListening(); completion(code) }
    }
}
    
    func joinRoom(code: String, userName: String, avatar: String? = nil, avatarBase64: String? = nil, completion: @escaping (Bool, String?) -> Void) {
    self.userName = userName; self.userId = UUID().uuidString; self.roomCode = code; self.isHost = false
    self.avatarBase64 = avatarBase64 ?? ""
    get(path: "rooms/\(code)/info") { [weak self] (data: [String: Any]?) in
        guard let self = self, let data = data, data["code"] != nil else { DispatchQueue.main.async { completion(false, nil) }; return }
        let roomName = data["roomName"] as? String ?? ""
        let av = avatar ?? WatchTogetherService.defaultAvatars[abs(self.userId.hashValue) % WatchTogetherService.defaultAvatars.count]
        let participant: [String: Any] = ["userId": self.userId, "userName": self.userName, "avatar": av, "avatarBase64": avatarBase64 ?? "", "isOnline": true]
        self.put(path: "rooms/\(code)/info/participants/\(self.userId)", data: participant) { success in
            DispatchQueue.main.async {
                if success { self.currentRoomCode = code; self.currentRoomName = roomName; self.isInRoom = true; self.startListening(); completion(true, roomName) }
                else { completion(false, nil) }
            }
        }
    }
}
    
    func leaveRoom() {
        timer?.invalidate(); timer = nil
        delete(path: "rooms/\(roomCode)/info/participants/\(userId)") { _ in }
        isInRoom = false; isHost = false; currentRoomCode = ""; currentRoomName = ""
        messages = []; participants = []; roomCode = ""; userId = ""
    }
    
    func sendPlaybackState(action: String, time: Double) {
        let state: [String: Any] = ["action": action, "time": time, "timestamp": Date().timeIntervalSince1970]
        put(path: "rooms/\(roomCode)/playback", data: state)
    }
    
    func sendEpisodeSync(seasonNumber: Int?, episodeNumber: Int?, action: String = "play", time: Double = 0) {
        var state: [String: Any] = ["action": action, "time": time, "timestamp": Date().timeIntervalSince1970]
        if let sn = seasonNumber { state["seasonNumber"] = sn }
        if let en = episodeNumber { state["episodeNumber"] = en }
        put(path: "rooms/\(roomCode)/playback", data: state)
    }
    
    func sendMessage(text: String) {
    let avatar = userAvatar
    let msg = ChatMessage(userId: userId, userName: userName, avatar: avatar, text: text, timestamp: Date().timeIntervalSince1970, avatarBase64: avatarBase64)
    if let data = try? JSONEncoder().encode(msg), let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        let msgId = "\(Int(msg.timestamp * 1000))"
        put(path: "rooms/\(roomCode)/messages/\(msgId)", data: dict)
    }
}
    
    private func startListening() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in self?.fetchUpdates() }
    }
    
    private func fetchUpdates() {
        guard !roomCode.isEmpty else { return }
        get(path: "rooms/\(roomCode)/playback") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data, let action = data["action"] as? String, let time = data["time"] as? Double else { return }
            DispatchQueue.main.async {
                self.remoteState = RemotePlaybackState(action: action, time: time, timestamp: data["timestamp"] as? Double ?? 0, episodeNumber: data["episodeNumber"] as? Int, seasonNumber: data["seasonNumber"] as? Int)
            }
        }
        get(path: "rooms/\(roomCode)/messages") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data else { return }
            let sorted = data.compactMap { _, value -> ChatMessage? in
                guard let dict = value as? [String: Any], let jsonData = try? JSONSerialization.data(withJSONObject: dict), let msg = try? JSONDecoder().decode(ChatMessage.self, from: jsonData) else { return nil }
                return msg
            }.sorted { $0.timestamp < $1.timestamp }
            DispatchQueue.main.async { self.messages = Array(sorted.suffix(50)) }
        }
        get(path: "rooms/\(roomCode)/info") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data, let roomName = data["roomName"] as? String else { return }
            DispatchQueue.main.async { self.currentRoomName = roomName }
        }
        get(path: "rooms/\(roomCode)/info/participants") { [weak self] (data: [String: Any]?) in
            guard let self = self, let data = data else { return }
            let parts = data.compactMap { _, value -> Participant? in
                guard let dict = value as? [String: Any], let userId = dict["userId"] as? String, let userName = dict["userName"] as? String else { return nil }
                return Participant(userId: userId, userName: userName, avatar: dict["avatar"] as? String ?? "🐱", isOnline: dict["isOnline"] as? Bool ?? true)
            }
            DispatchQueue.main.async { self.participants = parts }
        }
    }
    
    private func get<T>(path: String, completion: @escaping (T?) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(path).json") else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? T else { completion(nil); return }
            completion(json)
        }.resume()
    }
    
    private func put(path: String, data: Any, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(baseURL)/\(path).json"), let body = try? JSONSerialization.data(withJSONObject: data) else { completion?(false); return }
        var req = URLRequest(url: url); req.httpMethod = "PUT"; req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: req) { _, response, _ in completion?((response as? HTTPURLResponse)?.statusCode == 200) }.resume()
    }
    
    private func delete(path: String, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(baseURL)/\(path).json") else { completion?(false); return }
        var req = URLRequest(url: url); req.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: req) { _, response, _ in completion?((response as? HTTPURLResponse)?.statusCode == 200) }.resume()
    }
}