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
    var backdropPath: String?
    var currentTime: String
}

// MARK: - Event Log Entry
struct EventLogEntry: Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
    var relativeTime: String {
        let diff = Int(Date().timeIntervalSince(timestamp))
        if diff < 5 { return "vừa xong" }
        if diff < 60 { return "\(diff)s trước" }
        if diff < 3600 { return "\(diff/60)p trước" }
        return "\(diff/3600)h trước"
    }
}

// MARK: - Flying Emoji Model
struct FlyingEmoji: Identifiable {
    let id = UUID()
    let emoji: String
    var offsetY: CGFloat = 0
    var opacity: Double = 1
    var xOffset: CGFloat
}

// MARK: - Main View
struct WatchTogetherRoomView: View {
    @StateObject private var service = WatchTogetherService.shared
    @State private var player = AVPlayer()
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var showViewerPanel = false
    @State private var showEpisodePanel = false
    @State private var watchMessage = ""
    @State private var userName = ""
    @State private var roomName = ""
    @State private var joinCode = ""
    @State private var showCreateRoom = false
    @State private var showSearchMovie = false
    @State private var showControls = false
    @State private var controlsTimer: Timer?
    @State private var isLandscape = false
    @State private var currentMovieTitle = ""
    @State private var pipController: AVPictureInPictureController?
    @FocusState private var isInputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var currentMovie: Movie?
    @State private var seasons: [TVSeason] = []
    @State private var selectedSeason: TVSeason?
    @State private var episodes: [TVEpisode] = []
    @State private var selectedEpisode: TVEpisode?
    @State private var eventLogs: [EventLogEntry] = []
    @State private var flyingEmojis: [FlyingEmoji] = []
    @State private var dominantColor: Color = Color(red: 0.05, green: 0.02, blue: 0.12)
    @State private var showRoomEndingNotice = false
    @State private var roomEmptyTimer: Timer?
    
    @State private var fakeRooms: [FakeRoom] = [
        FakeRoom(roomName: "Deadpool nè", movieTitle: "Deadpool & Wolverine", viewerCount: 6, avatars: ["🐱","🐶","🐰","🐻","🐼","🐨"], isPrivate: false, backdropPath: "/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg", currentTime: "01:12:45"),
        FakeRoom(roomName: "kinh dị", movieTitle: "The Nun II", viewerCount: 3, avatars: ["🦊","🐸","🐵"], isPrivate: true, backdropPath: "/5gzzkR7y3hnY8AD1wXjCnVlHba5.jpg", currentTime: "00:32:18"),
        FakeRoom(roomName: "⚡ Marvel Marathon", movieTitle: "Avengers: Endgame", viewerCount: 6, avatars: ["🐱","🐼","🐨","🐯","🦊","🐙"], isPrivate: false, backdropPath: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", currentTime: "02:45:10"),
        FakeRoom(roomName: "Hàn xẻnggg", movieTitle: "Parasite", viewerCount: 4, avatars: ["🐶","🐰","🐷","🐹"], isPrivate: false, backdropPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", currentTime: "01:05:33"),
        FakeRoom(roomName: "Rock & Movie", movieTitle: "Bohemian Rhapsody", viewerCount: 4, avatars: ["🐻","🐼","🐨","🐯"], isPrivate: true, backdropPath: "/lHu1wtNaczFPgfDvJflLyh1HdxH.jpg", currentTime: "00:58:22"),
        FakeRoom(roomName: "cấm vào", movieTitle: "Dune: Part Two", viewerCount: 5, avatars: ["🦊","🐸","🐵","🐮","🐷"], isPrivate: false, backdropPath: "/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg", currentTime: "01:42:08"),
        FakeRoom(roomName: "babixinhiu", movieTitle: "Deadpool 3", viewerCount: 6, avatars: ["🐹","🐭","🦄","🐙","🐱","🐶"], isPrivate: false, backdropPath: "/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg", currentTime: "00:22:55"),
        FakeRoom(roomName: "ghost stories", movieTitle: "A Quiet Place", viewerCount: 3, avatars: ["🐰","🐻","🐼"], isPrivate: true, backdropPath: "/nAU74GmpUk7t5iklEp3bufwDq4n.jpg", currentTime: "00:47:12"),
        FakeRoom(roomName: "🎥 Indie", movieTitle: "Everything Everywhere", viewerCount: 2, avatars: ["🐨","🐯"], isPrivate: false, backdropPath: "/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg", currentTime: "01:28:40"),
        FakeRoom(roomName: "🇯🇵 Animu", movieTitle: "Spirited Away", viewerCount: 4, avatars: ["🦊","🐸","🐵","🐮"], isPrivate: false, backdropPath: "/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg", currentTime: "01:55:00"),
        FakeRoom(roomName: "🔥 Hot Hòn Họt", movieTitle: "John Wick 4", viewerCount: 5, avatars: ["🐷","🐹","🐭","🦄","🐙"], isPrivate: false, backdropPath: "/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg", currentTime: "00:15:30"),
        FakeRoom(roomName: "Romcom", movieTitle: "How to Lose a Guy", viewerCount: 3, avatars: ["🐮","🐷","🐹"], isPrivate: false, backdropPath: "/5gzzkR7y3hnY8AD1wXjCnVlHba5.jpg", currentTime: "00:38:55"),
    ]
    
    @State private var refreshTimer: Timer?
    let backupRoomNames = ["ai đoá ai đóa", "gigi ngungục", "ziku", "Music & Movie", "📺 Series Addict", "bò cinema", "newjeans neverdie", "🔥 Trending Now", "Hidden Gems", "hanpham", "🌴 Tropical Night", "siu anh hùng"]
    let backupMovies = ["Barbie", "The Batman", "Spider-Man", "Joker", "Inception", "Tenet", "Dunkirk", "Memento", "La La Land", "Whiplash", "Get Out", "Us"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if service.isInRoom { inRoomView }
            else if showCreateRoom { createRoomView }
            else { lobbyView }
            
            ForEach(flyingEmojis) { fe in
                Text(fe.emoji)
                    .font(.system(size: 32))
                    .offset(y: fe.offsetY)
                    .offset(x: fe.xOffset)
                    .opacity(fe.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startFakeRoomRefresh()
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { n in
                if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.28)) { keyboardHeight = frame.height }
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeOut(duration: 0.28)) { keyboardHeight = 0 }
            }
        }
        .onDisappear { refreshTimer?.invalidate(); controlsTimer?.invalidate(); roomEmptyTimer?.invalidate() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let o = UIDevice.current.orientation; isLandscape = o == .landscapeLeft || o == .landscapeRight
        }
    }
    
    func startFakeRoomRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                for _ in 0..<3 {
                    let idx = Int.random(in: 0..<fakeRooms.count)
                    fakeRooms[idx].roomName = backupRoomNames.randomElement() ?? fakeRooms[idx].roomName
                    fakeRooms[idx].movieTitle = backupMovies.randomElement() ?? fakeRooms[idx].movieTitle
                    fakeRooms[idx].viewerCount = Int.random(in: 2...6)
                    let m = Int.random(in: 0...120); let s = Int.random(in: 0...59)
                    fakeRooms[idx].currentTime = String(format: "%02d:%02d:%02d", m/60, m, s)
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
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30)).foregroundColor(.white)
                        .shadow(color: .white.opacity(0.3), radius: 6)
                }
            }.padding(.horizontal, 20).padding(.top, 50).padding(.bottom, 16)
            ScrollView {
                VStack(spacing: 14) { ForEach(fakeRooms) { room in fakeRoomCard(room) } }
                    .padding(.horizontal, 16).padding(.bottom, 120)
            }
        }
    }
    
    func fakeRoomCard(_ room: FakeRoom) -> some View {
        VStack(spacing: 0) {
            // Backdrop 16:9
            ZStack(alignment: .bottomLeading) {
                if let path = room.backdropPath, let url = URL(string: "https://image.tmdb.org/t/p/w500\(path)") {
                    CachedAsyncImage(url: url)
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .center, endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Material.ultraThinMaterial.opacity(0.4))
                        .frame(height: 140)
                        .overlay(Image(systemName: "play.circle.fill").font(.system(size: 30)).foregroundColor(.white.opacity(0.5)))
                }
                
                // Progress bar nhỏ
                VStack(spacing: 4) {
                    GeometryReader { g in
                        Capsule().fill(.white.opacity(0.12)).frame(height: 2)
                            .overlay(
                                Capsule().fill(.white.opacity(0.5))
                                    .frame(width: g.size.width * CGFloat.random(in: 0.2...0.8), height: 2),
                                alignment: .leading
                            )
                    }.frame(height: 2)
                    HStack {
                        Text(room.currentTime)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        HStack(spacing: 3) {
                            Circle().fill(Color.green).frame(width: 5, height: 5)
                            Text("Đang xem")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }.padding(.horizontal, 10).padding(.bottom, 8)
            }
            
            // Info row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.movieTitle)
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Text(room.roomName)
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                }
                Spacer()
                HStack(spacing: -8) {
                    ForEach(room.avatars.prefix(3), id: \.self) { av in
                        Text(av).font(.system(size: 10)).frame(width: 22, height: 22)
                            .background(Circle().fill(Material.ultraThinMaterial.opacity(0.7)))
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                    }
                    if room.viewerCount > 3 {
                        Text("+\(room.viewerCount - 3)").font(.system(size: 8)).foregroundColor(.white.opacity(0.5))
                    }
                }
                if room.isPrivate {
                    Image(systemName: "lock.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                }
            }.padding(.horizontal, 8).padding(.vertical, 10)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Material.ultraThinMaterial.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
    }
    
    // MARK: - Create Room
    var createRoomView: some View {
        VStack(spacing: 24) {
            HStack {
                Button { showCreateRoom = false } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .padding(12).background(Circle().fill(Material.ultraThinMaterial.opacity(0.4)))
                        .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 0.5))
                }
                Spacer(); Text("Tạo phòng").font(.title3.bold()).foregroundColor(.white); Spacer(); Circle().fill(.clear).frame(width: 44)
            }.padding(.horizontal, 16).padding(.top, 50)
            VStack(spacing: 16) {
                HStack {
                    Text("Avatar của bạn:").font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(WatchTogetherService.defaultAvatars[abs((userName.isEmpty ? "guest" : userName).hashValue) % WatchTogetherService.defaultAvatars.count])
                        .font(.system(size: 28)).frame(width: 44, height: 44)
                        .background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                        .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                }.padding(.horizontal, 4)
                TextField("Tên của bạn", text: $userName).font(.system(size: 15)).foregroundColor(.white)
                    .padding(16).background(RoundedRectangle(cornerRadius: 16).fill(Material.ultraThinMaterial.opacity(0.25)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 0.5))
                TextField("Tên phòng (tuỳ chọn)", text: $roomName).font(.system(size: 15)).foregroundColor(.white)
                    .padding(16).background(RoundedRectangle(cornerRadius: 16).fill(Material.ultraThinMaterial.opacity(0.25)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 0.5))
                Button {
                    guard !userName.isEmpty else { return }
                    service.createRoom(roomName: roomName.isEmpty ? "Phòng của \(userName)" : roomName, userName: userName) { _ in showCreateRoom = false }
                } label: {
                    HStack { Image(systemName: "movieclapper.fill"); Text("Tạo phòng").font(.headline) }
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Capsule().fill(LinearGradient(colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.3)], startPoint: .leading, endPoint: .trailing)))
                        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                        .shadow(color: .purple.opacity(0.2), radius: 10, y: 4)
                }
                HStack(spacing: 12) {
                    Rectangle().fill(.white.opacity(0.15)).frame(height: 1)
                    Text("hoặc tham gia").font(.system(size: 11)).foregroundColor(.gray)
                    Rectangle().fill(.white.opacity(0.15)).frame(height: 1)
                }
                TextField("Nhập mã phòng 6 số", text: $joinCode).font(.system(size: 15)).foregroundColor(.white)
                    .padding(16).background(RoundedRectangle(cornerRadius: 16).fill(Material.ultraThinMaterial.opacity(0.25)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 0.5)).keyboardType(.numberPad)
                Button {
                    guard !userName.isEmpty, joinCode.count == 6 else { return }
                    service.joinRoom(code: joinCode, userName: userName) { success, _ in if success { showCreateRoom = false } else { print("❌ Không tìm thấy phòng \(joinCode)") } }
                } label: {
                    HStack { Image(systemName: "arrow.right.circle.fill"); Text("Vào phòng").font(.headline) }
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Capsule().fill(Material.ultraThinMaterial.opacity(0.5)))
                        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                }
            }.padding(.horizontal, 24)
            Spacer()
        }.background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - In Room
    var inRoomView: some View {
        GeometryReader { geo in
            ZStack {
                if isLandscape {
                    HStack(spacing: 0) {
                        ZStack {
                            CustomPlayerVC(player: player, pipController: $pipController)
                            videoControlsOverlay
                        }
                        .frame(width: geo.size.width * 0.72)
                        .onTapGesture { toggleControlsInRoom() }
                        
                        // Chat panel mỏng bên phải như YouTube
                        youtubeStyleChatPanel
                            .frame(width: geo.size.width * 0.28)
                    }.ignoresSafeArea()
                } else {
                    VStack(spacing: 0) {
                        ZStack {
                            CustomPlayerVC(player: player, pipController: $pipController)
                            VStack(spacing: 0) {
                                HStack {
                                    Button {
                                        player.pause(); player.replaceCurrentItem(with: nil); service.leaveRoom()
                                        startRoomEmptyCountdown()
                                    } label: {
                                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                            .padding(9).background(Circle().fill(Material.ultraThinMaterial.opacity(0.6)))
                                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                                    }
                                    Spacer()
                                    if showControls {
                                        HStack(spacing: 8) {
                                            Button { showEpisodePanel = true } label: {
                                                Image(systemName: "list.bullet").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                                                    .padding(7).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                                            }
                                            Button { pipController?.startPictureInPicture() } label: {
                                                Image(systemName: "pip.enter").font(.system(size: 12)).foregroundColor(.white)
                                                    .padding(7).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                                            }
                                            Button { toggleOrientation() } label: {
                                                Image(systemName: "rotate.right").font(.system(size: 12)).foregroundColor(.white)
                                                    .padding(7).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                                            }
                                        }
                                    }
                                }.padding(.horizontal, 12).padding(.top, 50)
                                if showControls { dynamicIslandView.padding(.top, 8).transition(.move(edge: .top).combined(with: .opacity)) }
                                Spacer()
                                if showControls {
                                    HStack(spacing: 50) {
                                        Button { seek(-10) } label: {
                                            Image(systemName: "gobackward.10").font(.system(size: 26)).foregroundColor(.white)
                                                .padding(14).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                                                .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                                        }
                                        Button {
                                            if player.rate == 0 { player.play() } else { player.pause() }
                                            if service.isHost { service.sendPlaybackState(action: player.rate == 0 ? "play" : "pause", time: currentTime) }
                                        } label: {
                                            Image(systemName: player.rate == 0 ? "play.fill" : "pause.fill").font(.system(size: 34)).foregroundColor(.white)
                                                .padding(20).background(Circle().fill(Material.ultraThinMaterial.opacity(0.6)))
                                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                                                .shadow(color: .white.opacity(0.1), radius: 12)
                                        }
                                        Button { seek(10) } label: {
                                            Image(systemName: "goforward.10").font(.system(size: 26)).foregroundColor(.white)
                                                .padding(14).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                                                .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                                        }
                                    }.transition(.opacity).padding(.bottom, 20)
                                }
                            }
                        }
                        .frame(height: geo.size.height * 0.42)
                        .onTapGesture { toggleControlsInRoom() }
                        
                        imessageChatPanel
                    }
                }
                
                // Room ending notice overlay
                if showRoomEndingNotice {
                    VStack(spacing: 12) {
                        Image(systemName: "door.left.hand.open").font(.system(size: 36)).foregroundColor(.white.opacity(0.6))
                        Text("5 phút nữa phòng sẽ biến mất")
                            .font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.7))
                        Text("Quay lại xem tiếp?")
                            .font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
                        Button {
                            showRoomEndingNotice = false
                            roomEmptyTimer?.invalidate()
                        } label: {
                            Text("Ở lại").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                .padding(.horizontal, 24).padding(.vertical, 8)
                                .background(Capsule().fill(Material.ultraThinMaterial.opacity(0.5)))
                        }
                    }
                    .padding(30)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Material.ultraThinMaterial.opacity(0.3)))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 0.5))
                }
            }
        }
        .ignoresSafeArea().animation(.easeInOut(duration: 0.3), value: showControls)
        .sheet(isPresented: $showViewerPanel) { viewerPanel.presentationDetents([.medium, .large]) }
        .sheet(isPresented: $showEpisodePanel) { episodePanel.presentationDetents([.medium]) }
        .sheet(isPresented: $showSearchMovie) { SearchView(onSelectMovie: { movie in loadMovieForRoom(movie) }) }
        .onAppear {
            player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { t in
                currentTime = t.seconds; if let d = player.currentItem?.duration, d.isNumeric { duration = d.seconds }
            }
            checkRoomEmpty()
        }
        .onChange(of: service.participants.count) { _ in checkRoomEmpty() }
        .onChange(of: service.remoteState?.timestamp) { _ in handleRemoteState() }
        .onChange(of: player.rate) { newRate in
            if service.isInRoom && service.isHost { service.sendPlaybackState(action: newRate > 0 ? "play" : "pause", time: currentTime) }
        }
    }
    
    func checkRoomEmpty() {
        let others = service.participants.filter { $0.userId != service.userId && $0.isOnline }
        if others.isEmpty && service.isInRoom {
            roomEmptyTimer?.invalidate()
            roomEmptyTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
                withAnimation { showRoomEndingNotice = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
                    if service.isInRoom { service.leaveRoom() }
                }
            }
        } else {
            roomEmptyTimer?.invalidate()
            withAnimation { showRoomEndingNotice = false }
        }
    }
    
    func startRoomEmptyCountdown() {
        roomEmptyTimer?.invalidate()
        roomEmptyTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
            withAnimation { showRoomEndingNotice = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
                if service.isInRoom { service.leaveRoom() }
            }
        }
    }
    
    func handleRemoteState() {
        guard let state = service.remoteState, !service.isHost else { return }
        let target = CMTime(seconds: state.time, preferredTimescale: 600)
        if let ep = state.episodeNumber, let sn = state.seasonNumber {
            if selectedEpisode?.episodeNumber != ep || selectedSeason?.seasonNumber != sn {
                Task {
                    if let detail = try? await APIService.shared.fetchSeasonDetail(tvId: currentMovie?.id ?? 0, seasonNumber: sn),
                       let episode = detail.episodes.first(where: { $0.episodeNumber == ep }) {
                        await MainActor.run {
                            selectedSeason = seasons.first(where: { $0.seasonNumber == sn })
                            selectedEpisode = episode
                            loadEpisode(episode)
                        }
                    }
                }
            }
        }
        if state.action == "play" { player.seek(to: target); player.play() }
        else if state.action == "pause" { player.seek(to: target); player.pause() }
        else if state.action == "seek" { player.seek(to: target) }
    }
    
    func addEventLog(_ msg: String) {
        eventLogs.append(EventLogEntry(text: "\(service.userAvatar) \(msg)", timestamp: Date()))
        if eventLogs.count > 5 { eventLogs.removeFirst() }
    }
    
    func toggleOrientation() {
        guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        ws.requestGeometryUpdate(.iOS(interfaceOrientations: isLandscape ? .portrait : .landscapeRight))
    }
    
    var dynamicIslandView: some View {
        Button { showEpisodePanel = true } label: {
            Text(currentMovieTitle.isEmpty ? "Chọn phim" : currentMovieTitle)
                .font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(Material.ultraThinMaterial.opacity(0.7)))
                .overlay(Capsule().stroke(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
        }
    }
    
    var videoControlsOverlay: some View {
        VStack {
            Spacer()
            if showControls {
                HStack(spacing: 45) {
                    Button { seek(-10) } label: {
                        Image(systemName: "gobackward.10").font(.system(size: 22)).foregroundColor(.white)
                            .padding(10).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                    }
                    Button { player.rate == 0 ? player.play() : player.pause() } label: {
                        Image(systemName: player.rate == 0 ? "play.fill" : "pause.fill").font(.system(size: 28)).foregroundColor(.white)
                            .padding(14).background(Circle().fill(Material.ultraThinMaterial.opacity(0.6)))
                            .shadow(color: .white.opacity(0.1), radius: 10)
                    }
                    Button { seek(10) } label: {
                        Image(systemName: "goforward.10").font(.system(size: 22)).foregroundColor(.white)
                            .padding(10).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                    }
                }.padding(.bottom, 24).transition(.opacity)
            }
            HStack(spacing: 10) {
                Spacer()
                Button { pipController?.startPictureInPicture() } label: {
                    Image(systemName: "pip.enter").font(.system(size: 12)).foregroundColor(.white)
                        .padding(7).background(Circle().fill(Material.ultraThinMaterial.opacity(0.45)))
                }
                Button { toggleOrientation() } label: {
                    Image(systemName: "rotate.right").font(.system(size: 12)).foregroundColor(.white)
                        .padding(7).background(Circle().fill(Material.ultraThinMaterial.opacity(0.45)))
                }
            }.padding(.trailing, 12).padding(.bottom, 8)
        }
    }
    
    func toggleControlsInRoom() {
        withAnimation(.easeInOut(duration: 0.25)) { showControls.toggle() }
        controlsTimer?.invalidate()
        if showControls { controlsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.3)) { showControls = false } } }
    }
    
    // MARK: - Chat (Portrait)
    var imessageChatPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentMovieTitle.isEmpty ? "🎬 Chưa chọn phim" : "🎬 \(currentMovieTitle)")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Text("Phòng của \(service.currentRoomName)")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                HStack(spacing: 8) {
                    Button { showSearchMovie = true } label: {
                        Image(systemName: "magnifyingglass").font(.system(size: 13)).foregroundColor(.white)
                            .padding(7).background(Circle().fill(Material.ultraThinMaterial.opacity(0.4)))
                            .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))
                    }
                    Button { showViewerPanel = true } label: {
                        HStack(spacing: -6) {
                            ForEach(service.participants.prefix(3), id: \.userId) { p in
                                Text(p.avatar).font(.system(size: 10)).frame(width: 18, height: 18)
                                    .background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                            }
                        }.padding(6).background(Capsule().fill(Material.ultraThinMaterial.opacity(0.4)))
                            .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 18).fill(Material.ultraThinMaterial.opacity(0.35)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08), lineWidth: 0.5))
            .padding(.horizontal, 8).padding(.top, 6)
            
            if duration > 0 {
                VStack(spacing: 4) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.08)).frame(height: 3)
                            Capsule()
                                .fill(LinearGradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, g.size.width * CGFloat(currentTime / max(duration, 1))), height: 3)
                            Circle().fill(.white).frame(width: 10, height: 10)
                                .shadow(color: .white.opacity(0.4), radius: 3)
                                .offset(x: max(0, min(g.size.width - 10, g.size.width * CGFloat(currentTime / max(duration, 1)) - 5)))
                        }
                    }.frame(height: 10)
                }.padding(.horizontal, 16).padding(.vertical, 4)
            }
            
            if !eventLogs.isEmpty {
                VStack(spacing: 1) {
                    ForEach(eventLogs) { log in
                        HStack(spacing: 6) {
                            Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5)
                            Text(log.text).font(.system(size: 9)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                            Text("· \(log.relativeTime)").font(.system(size: 8)).foregroundColor(.white.opacity(0.3))
                            Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5)
                        }.padding(.horizontal, 14).padding(.vertical, 2)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(["😭","🤣","👏","❤️","🔥","💀","🎉","😍","🙏","💯"], id: \.self) { e in
                        Button { sendReaction(e) } label: { Text(e).font(.system(size: 26)) }
                    }
                }.padding(.horizontal, 16).padding(.vertical, 8)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        Color.clear.frame(height: 4)
                        ForEach(Array(service.messages.enumerated()), id: \.element.id) { idx, msg in
                            imessageBubble(msg, showAvatar: shouldShowAvatar(at: idx)).id(msg.id)
                        }
                        Color.clear.frame(height: 4)
                    }.padding(.horizontal, 14)
                }
                .onChange(of: service.messages.count) { _ in
                    if let last = service.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            
            HStack(spacing: 10) {
                TextField("Nhắn tin...", text: $watchMessage)
                    .focused($isInputFocused).font(.system(size: 16)).foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Material.ultraThinMaterial.opacity(0.5)))
                    .overlay(RoundedRectangle(cornerRadius: 25).stroke(.white.opacity(0.15), lineWidth: 0.5))
                    .onSubmit { sendImessage() }
                if !watchMessage.isEmpty {
                    Button { sendImessage() } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 38)).foregroundColor(.white)
                            .shadow(color: .blue.opacity(0.3), radius: 6)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .padding(.bottom, max(keyboardHeight - 30, 30))
            .animation(.easeOut(duration: 0.28), value: keyboardHeight)
        }
        .background(
            ZStack {
                dominantColor.opacity(0.25)
                Rectangle().fill(Material.ultraThinMaterial)
            }
        )
    }
    
    // MARK: - Chat (Landscape - YouTube style)
    var youtubeStyleChatPanel: some View {
        VStack(spacing: 0) {
            // Header gọn
            HStack {
                Text("💬 Live Chat")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Spacer()
                Text("\(service.participants.count)")
                    .font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 8).padding(.vertical, 8)
            .background(Material.ultraThinMaterial.opacity(0.4))
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(service.messages.enumerated()), id: \.element.id) { idx, msg in
                            youtubeChatBubble(msg).id(msg.id)
                        }
                    }.padding(.horizontal, 6)
                }
                .onChange(of: service.messages.count) { _ in
                    if let last = service.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            
            // React nhanh
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(["❤️","😭","🤣","🔥","👏","💀","🎉","😍"], id: \.self) { e in
                        Button { sendReaction(e) } label: { Text(e).font(.system(size: 18)) }
                    }
                }.padding(.horizontal, 8).padding(.vertical, 4)
            }
            
            // Input nhỏ
            HStack(spacing: 6) {
                TextField("Nhắn...", text: $watchMessage)
                    .focused($isInputFocused).font(.system(size: 13)).foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Material.ultraThinMaterial.opacity(0.5)))
                    .onSubmit { sendImessage() }
            }.padding(.horizontal, 6).padding(.vertical, 6).padding(.bottom, 4)
        }
        .background(Color.black.opacity(0.92))
    }
    
    func youtubeChatBubble(_ msg: WatchTogetherService.ChatMessage) -> some View {
        let isMe = msg.userId == service.userId
        return HStack(alignment: .top, spacing: 4) {
            Text(msg.avatar).font(.system(size: 10)).frame(width: 18, height: 18)
                .background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(msg.userName).font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7)).lineLimit(1)
                    if isMe { Text("· bạn").font(.system(size: 8)).foregroundColor(.blue.opacity(0.7)) }
                }
                Text(msg.text).font(.system(size: 12)).foregroundColor(.white).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }.padding(.vertical, 2)
    }
    
    func sendReaction(_ emoji: String) {
        // KHÔNG gửi message - chỉ animation bay
        let fe = FlyingEmoji(emoji: emoji, xOffset: CGFloat.random(in: -60...60))
        flyingEmojis.append(fe)
        withAnimation(.easeOut(duration: 1.2)) {
            if let idx = flyingEmojis.firstIndex(where: { $0.id == fe.id }) {
                flyingEmojis[idx].offsetY = -120
                flyingEmojis[idx].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { flyingEmojis.removeAll { $0.id == fe.id } }
    }
    
    func shouldShowAvatar(at index: Int) -> Bool {
        if index == 0 { return true }; return service.messages[index].userId != service.messages[index - 1].userId
    }
    
    func imessageBubble(_ msg: WatchTogetherService.ChatMessage, showAvatar: Bool) -> some View {
        let isMe = msg.userId == service.userId
        return HStack(alignment: .bottom, spacing: 8) {
            if !isMe {
                if showAvatar {
                    Text(msg.avatar).font(.system(size: 16)).frame(width: 32, height: 32)
                        .background(Circle().fill(Material.ultraThinMaterial.opacity(0.6)))
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))
                } else { Color.clear.frame(width: 32, height: 32) }
            } else { Spacer() }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                if showAvatar && !isMe { Text(msg.userName).font(.system(size: 10)).foregroundColor(.white.opacity(0.5)) }
                Text(msg.text).font(.system(size: 15)).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Material.ultraThinMaterial.opacity(isMe ? 0.55 : 0.35)))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(isMe ? 0.18 : 0.08), lineWidth: 0.5))
            }
            if isMe {
                if showAvatar {
                    Text(msg.avatar).font(.system(size: 16)).frame(width: 32, height: 32)
                        .background(Circle().fill(Material.ultraThinMaterial.opacity(0.6)))
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))
                } else { Color.clear.frame(width: 32, height: 32) }
            } else { Spacer() }
        }
    }
    
    func sendImessage() { let t = watchMessage.trimmingCharacters(in: .whitespaces); guard !t.isEmpty else { return }; service.sendMessage(text: t); watchMessage = "" }
    func seek(_ s: Double) { let t = max(0, min(currentTime + s, duration)); player.seek(to: CMTime(seconds: t, preferredTimescale: 600)); currentTime = t; if service.isHost { service.sendPlaybackState(action: "seek", time: t) } }
    func formatTime(_ s: Double) -> String { let ts = Int(max(0, s)); let h = ts / 3600; let m = (ts % 3600) / 60; let sec = ts % 60; if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }; return String(format: "%02d:%02d", m, sec) }
    
    // MARK: - Load Movie
    func loadMovieForRoom(_ movie: Movie) {
        currentMovieTitle = movie.title; currentMovie = movie; selectedSeason = nil; episodes = []; selectedEpisode = nil; seasons = []
        addEventLog("🎬 Chọn \(movie.title)")
        dominantColor = Color(red: 0.05, green: 0.02, blue: 0.12)
        if movie.mediaType == "tv" {
            Task {
                if let s = try? await APIService.shared.fetchTVSeasons(tvId: movie.id), !s.isEmpty {
                    await MainActor.run { self.seasons = s }
                }
            }
        }
        Task {
            do {
                let imdbID = try await fetchIMDBID(for: movie.id, mediaType: movie.mediaType)
                var streamURL: URL?
                streamURL = try? await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: nil, episode: nil) { cont.resume(with: $0) } }
                if streamURL == nil { streamURL = try? await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in SofaflixService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: nil, episode: nil) { cont.resume(with: $0) } } }
                guard let url = streamURL else { addEventLog("⚠️ Không tìm thấy stream"); return }
                await MainActor.run {
                    player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play()
                    if service.isHost { service.sendEpisodeSync(seasonNumber: nil, episodeNumber: nil, action: "play", time: 0) }
                }
            } catch { print("Load error: \(error)"); addEventLog("❌ Lỗi tải phim") }
        }
    }
    
    func loadEpisode(_ ep: TVEpisode) {
        guard let movie = currentMovie else { return }
        currentMovieTitle = "\(movie.title) - Tập \(ep.episodeNumber)"; selectedEpisode = ep
        addEventLog("📺 Chọn Tập \(ep.episodeNumber)")
        Task {
            do {
                let imdbID = try await fetchIMDBID(for: movie.id, mediaType: movie.mediaType)
                var streamURL: URL?
                streamURL = try? await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: ep.seasonNumber, episode: ep.episodeNumber) { cont.resume(with: $0) } }
                if streamURL == nil { streamURL = try? await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in SofaflixService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: ep.seasonNumber, episode: ep.episodeNumber) { cont.resume(with: $0) } } }
                guard let url = streamURL else { addEventLog("⚠️ Không tìm thấy stream tập \(ep.episodeNumber)"); return }
                await MainActor.run {
                    player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play()
                    if service.isHost { service.sendEpisodeSync(seasonNumber: ep.seasonNumber, episodeNumber: ep.episodeNumber, action: "play", time: 0) }
                }
            } catch { print("Load episode error: \(error)"); addEventLog("❌ Lỗi tải tập \(ep.episodeNumber)") }
        }
    }
    
    func fetchIMDBID(for tmdbID: Int, mediaType: String?) async throws -> String {
        if mediaType == "tv", let id = try? await APIService.shared.fetchExternalIDs(tvId: tmdbID), !id.isEmpty { return id }
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(tmdbID)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
        struct E: Codable { let imdb_id: String? }
        guard let id = try JSONDecoder().decode(E.self, from: data).imdb_id, !id.isEmpty else { throw NSError(domain: "", code: -1) }
        return id
    }
    
    // MARK: - Panels
    var viewerPanel: some View {
        VStack(spacing: 0) {
            Capsule().fill(.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 10)
            Text("Người xem (\(service.participants.count))").font(.headline).foregroundColor(.white).padding(.vertical, 14)
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(service.participants, id: \.userId) { p in
                        HStack(spacing: 14) {
                            Text(p.avatar).font(.system(size: 28)).frame(width: 50, height: 50).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5)))
                                .overlay(Circle().fill(p.isOnline ? Color.green : Color.gray).frame(width: 12, height: 12).overlay(Circle().stroke(Color.black, lineWidth: 2)).offset(x: 18, y: 18))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(p.userName).font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                                Text(p.isOnline ? "Đang xem" : "Đã rời").font(.system(size: 12)).foregroundColor(p.isOnline ? .green.opacity(0.8) : .gray)
                            }
                            Spacer()
                            if p.userId == service.currentUserId { Text("Bạn").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.6)).padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(Material.ultraThinMaterial.opacity(0.4))) }
                        }.padding(.horizontal, 20)
                    }
                }
            }
        }.background(Color.black.opacity(0.95))
    }
    
    var episodePanel: some View {
        VStack(spacing: 0) {
            Capsule().fill(.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 10)
            Text(currentMovieTitle.isEmpty ? "Chọn tập" : currentMovieTitle)
                .font(.headline).foregroundColor(.white).padding(.vertical, 10)
            
            if seasons.isEmpty && episodes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tv.slash").font(.system(size: 40)).foregroundColor(.gray)
                    Text("Phim lẻ hoặc chưa có season").font(.system(size: 13)).foregroundColor(.gray)
                    Button { showEpisodePanel = false; showSearchMovie = true } label: {
                        Text("Đổi phim khác").font(.system(size: 13)).foregroundColor(.blue)
                    }
                }.frame(maxHeight: .infinity)
            } else if let selSeason = selectedSeason {
                VStack(alignment: .leading, spacing: 6) {
                    Button { withAnimation { selectedSeason = nil; episodes = [] } } label: {
                        HStack {
                            Image(systemName: "chevron.left").font(.system(size: 11))
                            Text(selSeason.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white); Spacer()
                        }.padding(.horizontal, 18).padding(.vertical, 8)
                    }
                    Divider().background(.white.opacity(0.1))
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(episodes) { ep in
                                Button {
                                    selectedEpisode = ep; showEpisodePanel = false; loadEpisode(ep)
                                } label: {
                                    Text("\(ep.episodeNumber)").font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedEpisode?.id == ep.id ? .black : .white)
                                        .frame(height: 40).frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedEpisode?.id == ep.id ? AnyShapeStyle(Color.white) : AnyShapeStyle(Material.ultraThinMaterial.opacity(0.3)))
                                        )
                                }
                            }
                        }.padding(.horizontal, 18)
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(seasons) { season in
                            Button {
                                withAnimation {
                                    selectedSeason = season
                                    Task {
                                        if let detail = try? await APIService.shared.fetchSeasonDetail(tvId: currentMovie?.id ?? 0, seasonNumber: season.seasonNumber) {
                                            await MainActor.run { episodes = detail.episodes }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(season.name).font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                                        Text("\(season.episodeCount) tập").font(.system(size: 11)).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(.gray)
                                }.padding(.horizontal, 18).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Material.ultraThinMaterial.opacity(0.3)))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 0.5))
                            }
                        }
                    }.padding(.horizontal, 18).padding(.vertical, 10)
                }
            }
        }
        .background(Color.black.opacity(0.95))
    }
}