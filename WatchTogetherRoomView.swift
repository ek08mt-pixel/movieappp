import SwiftUI
import AVKit

// MARK: - Fake Room Model
struct FakeRoom: Identifiable {
    let id = UUID()
    var roomName: String
    var movieTitle: String
    var viewerCount: Int
    var avatars: [String]
    var isPrivate: Bool
}

// MARK: - Main View
struct WatchTogetherRoomView: View {
    @StateObject private var service = WatchTogetherService.shared
    @State private var player = AVPlayer()
    @State private var currentTime: Double = 0
    @State private var showViewerPanel = false
    @State private var watchMessage = ""
    @State private var userName = ""
    @State private var roomName = ""
    @State private var joinCode = ""
    @State private var showCreateRoom = false
    @State private var showSearchMovie = false
    @FocusState private var isInputFocused: Bool
    
    @State private var fakeRooms: [FakeRoom] = [
        FakeRoom(roomName: "Người deep", movieTitle: "Oppenheimer", viewerCount: 4, avatars: ["🐱","🐶","🐰","🐻"], isPrivate: false),
        FakeRoom(roomName: "🌙 Đêm kinh dị", movieTitle: "The Nun II", viewerCount: 3, avatars: ["🦊","🐸","🐵"], isPrivate: true),
        FakeRoom(roomName: "cấm zo", movieTitle: "How to Lose a Guy", viewerCount: 5, avatars: ["🐮","🐷","🐹","🐭","🦄"], isPrivate: false),
        FakeRoom(roomName: "⚡ Marvel Marathon", movieTitle: "Avengers: Endgame", viewerCount: 6, avatars: ["🐱","🐼","🐨","🐯","🦊","🐙"], isPrivate: false),
        FakeRoom(roomName: "Hàn xẻng xỉu up", movieTitle: "Parasite", viewerCount: 2, avatars: ["🐶","🐰"], isPrivate: false),
        FakeRoom(roomName: "Rock & Movie", movieTitle: "Bohemian Rhapsody", viewerCount: 4, avatars: ["🐻","🐼","🐨","🐯"], isPrivate: true),
        FakeRoom(roomName: "🌌 Sci fi Universe", movieTitle: "Dune: Part Two", viewerCount: 5, avatars: ["🦊","🐸","🐵","🐮","🐷"], isPrivate: false),
        FakeRoom(roomName: "babi xinh iuu", movieTitle: "Deadpool 3", viewerCount: 6, avatars: ["🐹","🐭","🦄","🐙","🐱","🐶"], isPrivate: false),
        FakeRoom(roomName: "👻 Ma sì to ri", movieTitle: "A Quiet Place", viewerCount: 3, avatars: ["🐰","🐻","🐼"], isPrivate: true),
        FakeRoom(roomName: "Indie Corner", movieTitle: "Everything Everywhere", viewerCount: 2, avatars: ["🐨","🐯"], isPrivate: false),
        FakeRoom(roomName: "Anime", movieTitle: "Spirited Away", viewerCount: 4, avatars: ["🦊","🐸","🐵","🐮"], isPrivate: false),
        FakeRoom(roomName: "🔥 Hot Pick", movieTitle: "John Wick 4", viewerCount: 5, avatars: ["🐷","🐹","🐭","🦄","🐙"], isPrivate: false),
    ]
    
    @State private var refreshTimer: Timer?
    let backupRoomNames = ["ai đoá ai đóa", "gigi ngungục", "ziku", "Music & Movie", "📺 Series Addict", "bò cinema", "newjeans neverdie", "🔥 Trending Now", "Hidden Gems", "hanpham", "🌴 Tropical Night", "siu anh hùng"]
    let backupMovies = ["Barbie", "The Batman", "Spider-Man", "Joker", "Inception", "Tenet", "Dunkirk", "Memento", "La La Land", "Whiplash", "Get Out", "Us"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if service.isInRoom {
                inRoomView
            } else if showCreateRoom {
                createRoomView
            } else {
                lobbyView
            }
        }
        .onAppear { startFakeRoomRefresh() }
        .onDisappear { refreshTimer?.invalidate() }
    }
    
    func startFakeRoomRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                for _ in 0..<3 {
                    let idx = Int.random(in: 0..<fakeRooms.count)
                    fakeRooms[idx].roomName = backupRoomNames.randomElement() ?? fakeRooms[idx].roomName
                    fakeRooms[idx].movieTitle = backupMovies.randomElement() ?? fakeRooms[idx].movieTitle
                    fakeRooms[idx].viewerCount = Int.random(in: 2...6)
                }
            }
        }
    }
    
    // MARK: - Lobby
    var lobbyView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Xem chung").font(.title2.bold()).foregroundColor(.white)
                Spacer()
                Button { showCreateRoom = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20).padding(.top, 50).padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(fakeRooms) { room in fakeRoomCard(room) }
                }
                .padding(.horizontal, 16).padding(.bottom, 120)
            }
        }
    }
    
    func fakeRoomCard(_ room: FakeRoom) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.35)).frame(width: 64, height: 88)
                .overlay(Image(systemName: "play.circle.fill").font(.system(size: 22)).foregroundColor(.white.opacity(0.7)))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(room.roomName).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Image(systemName: room.isPrivate ? "lock.fill" : "globe").font(.system(size: 8)).foregroundColor(.white.opacity(0.4)).padding(3).background(Circle().fill(.white.opacity(0.1)))
                }
                Text(room.movieTitle).font(.system(size: 12)).foregroundColor(.gray)
                HStack(spacing: 8) {
                    HStack(spacing: -8) {
                        ForEach(room.avatars.prefix(4), id: \.self) { av in
                            Text(av).font(.system(size: 11)).frame(width: 22, height: 22)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.6))).overlay(Circle().stroke(.black.opacity(0.3), lineWidth: 0.5))
                        }
                    }
                    Text("\(room.viewerCount) người").font(.system(size: 11)).foregroundColor(.white.opacity(0.5)).padding(.leading, 4)
                }
            }
            Spacer()
            VStack(spacing: 3) {
                Circle().fill(.green).frame(width: 6, height: 6)
                Text("Live").font(.system(size: 7)).foregroundColor(.green.opacity(0.8))
            }.padding(.trailing, 4)
        }
        .padding(12).background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.22)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.06), lineWidth: 0.5))
    }
    
    // MARK: - Create Room
    var createRoomView: some View {
        VStack(spacing: 20) {
            HStack {
                Button { showCreateRoom = false } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                }
                Spacer(); Text("Tạo phòng").font(.headline).foregroundColor(.white); Spacer()
                Circle().fill(.clear).frame(width: 40)
            }.padding(.horizontal, 16).padding(.top, 50)
            
            VStack(spacing: 14) {
                TextField("Tên của bạn", text: $userName).font(.system(size: 14)).foregroundColor(.white).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.2))).overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5))
                TextField("Tên phòng", text: $roomName).font(.system(size: 14)).foregroundColor(.white).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.2))).overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5))
                Button {
                    guard !userName.isEmpty else { return }
                    service.createRoom(roomName: roomName.isEmpty ? "Phòng của \(userName)" : roomName, userName: userName) { _ in showCreateRoom = false }
                } label: {
                    Text("Tạo phòng").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.4))).overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                }
                HStack {
                    Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5)
                    Text("hoặc").font(.caption).foregroundColor(.gray)
                    Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5)
                }
                TextField("Nhập mã phòng", text: $joinCode).font(.system(size: 14)).foregroundColor(.white).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.2))).overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5)).keyboardType(.numberPad)
                Button {
                    guard !userName.isEmpty, joinCode.count == 6 else { return }
                    service.joinRoom(code: joinCode, userName: userName) { success, _ in if success { showCreateRoom = false } }
                } label: {
                    Text("Vào phòng").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.4))).overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                }
            }.padding(.horizontal, 20)
            Spacer()
        }.background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - In Room
    var inRoomView: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                if isLandscape {
                    // Ngang: Video full + chat overlay phải
                    HStack(spacing: 0) {
                        CustomPlayerVC(player: player, pipController: .constant(nil))
                            .frame(width: geo.size.width * 0.62)
                        imessageChatPanel
                            .frame(width: geo.size.width * 0.38)
                    }
                    .ignoresSafeArea()
                } else {
                    // Dọc: Video trên + Chat iMessage dưới
                    VStack(spacing: 0) {
                        // Video
                        ZStack {
                            CustomPlayerVC(player: player, pipController: .constant(nil))
                            // Top bar overlay trên video
                            VStack {
                                HStack {
                                    Button {
                                        service.leaveRoom(); player.pause(); player.replaceCurrentItem(with: nil)
                                    } label: {
                                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                                    }
                                    Spacer()
                                    Text(service.currentRoomName).font(.caption).foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Button { showSearchMovie = true } label: {
                                            Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                                        }
                                        Button { showViewerPanel = true } label: {
                                            HStack(spacing: -4) {
                                                ForEach(service.participants.prefix(2), id: \.userId) { p in
                                                    Text(p.avatar).font(.system(size: 10)).frame(width: 20, height: 20).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                                                }
                                            }.padding(6).background(Capsule().fill(.ultraThinMaterial.opacity(0.4)))
                                        }
                                    }
                                }.padding(.horizontal, 12).padding(.top, 50)
                                Spacer()
                            }
                        }
                        .frame(height: geo.size.height * 0.42)
                        
                        // Chat iMessage
                        imessageChatPanel
                    }
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showViewerPanel) { viewerPanel.presentationDetents([.medium]) }
        .sheet(isPresented: $showSearchMovie) { SearchView(onSelectMovie: { movie in loadMovieForRoom(movie) }) }
        .onChange(of: service.remoteState?.timestamp) { _ in
            guard let state = service.remoteState, !service.isHost else { return }
            let target = CMTime(seconds: state.time, preferredTimescale: 600)
            if state.action == "play" { player.seek(to: target); player.play() }
            else if state.action == "pause" { player.seek(to: target); player.pause() }
            else if state.action == "seek" { player.seek(to: target) }
        }
        .onChange(of: player.rate) { newRate in
            if service.isInRoom && service.isHost { service.sendPlaybackState(action: newRate > 0 ? "play" : "pause", time: currentTime) }
        }
    }
    
    // MARK: - iMessage Chat Panel
    var imessageChatPanel: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text(service.currentRoomName)
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("#\(service.currentRoomCode)")
                    .font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.3))
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(service.messages) { msg in
                            imessageBubble(msg).id(msg.id)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
                .onChange(of: service.messages.count) { _ in
                    if let last = service.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .background(.ultraThinMaterial.opacity(0.15))
            
            // Input bar iMessage style
            HStack(spacing: 10) {
                TextField("Nhắn tin...", text: $watchMessage)
                    .focused($isInputFocused)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.4)))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 0.5))
                    .onSubmit { sendImessage() }
                
                if !watchMessage.isEmpty {
                    Button { sendImessage() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.5))
        }
        .background(.ultraThinMaterial.opacity(0.25))
    }
    
    func imessageBubble(_ msg: WatchTogetherService.ChatMessage) -> some View {
        let isMe = msg.userId == service.userId
        
        return HStack(alignment: .bottom, spacing: 8) {
            if !isMe {
                // Avatar người khác
                Text(msg.avatar).font(.system(size: 16))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
            } else { Spacer() }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(msg.userName).font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                Text(msg.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(isMe ? 0.5 : 0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(isMe ? 0.15 : 0.08), lineWidth: 0.5)
                    )
            }
            
            if isMe {
                Text(msg.avatar).font(.system(size: 16))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
            } else { Spacer() }
        }
    }
    
    func sendImessage() {
        let trimmed = watchMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        service.sendMessage(text: trimmed)
        watchMessage = ""
    }
    
    // MARK: - Load Movie
    func loadMovieForRoom(_ movie: Movie) {
        Task {
            do {
                let imdbID = try await fetchIMDBID(for: movie.id, mediaType: movie.mediaType)
                var streamURL: URL?
                do {
                    streamURL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                        PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: nil, episode: nil) { cont.resume(with: $0) }
                    }
                } catch { print("PhimAPI: \(error)") }
                if streamURL == nil {
                    do {
                        streamURL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                            SofaflixService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: nil, episode: nil) { cont.resume(with: $0) }
                        }
                    } catch { print("Sofaflix: \(error)") }
                }
                guard let url = streamURL else { return }
                await MainActor.run {
                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    player.play()
                    if service.isHost { service.sendPlaybackState(action: "play", time: 0) }
                }
            } catch { print("Load error: \(error)") }
        }
    }
    
    func fetchIMDBID(for tmdbID: Int, mediaType: String?) async throws -> String {
        if mediaType == "tv", let id = try? await APIService.shared.fetchExternalIDs(tvId: tmdbID), !id.isEmpty { return id }
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(tmdbID)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
        struct E: Codable { let imdb_id: String? }
        guard let id = try JSONDecoder().decode(E.self, from: data).imdb_id, !id.isEmpty else { throw NSError(domain: "", code: -1) }
        return id
    }
    
    // MARK: - Viewer Panel
    var viewerPanel: some View {
        VStack(spacing: 0) {
            Capsule().fill(.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 10)
            Text("Người xem (\(service.participants.count))").font(.headline).foregroundColor(.white).padding(.vertical, 12)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(service.participants, id: \.userId) { p in
                        HStack(spacing: 12) {
                            Text(p.avatar).font(.system(size: 28)).frame(width: 48, height: 48).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(Circle().fill(p.isOnline ? Color.green : Color.gray).frame(width: 10, height: 10).offset(x: 17, y: 17))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.userName).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                                Text(p.isOnline ? "Đang xem" : "Đã rời").font(.system(size: 11)).foregroundColor(.gray)
                            }
                            Spacer()
                        }.padding(.horizontal, 20)
                    }
                }
            }
        }.background(Color.black.opacity(0.95))
    }
}