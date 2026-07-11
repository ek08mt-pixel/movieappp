import SwiftUI
import AVKit

// MARK: - Fake Room Model
struct FakeRoom: Identifiable {
    let id = UUID()
    var roomName: String; var movieTitle: String; var viewerCount: Int
    var avatars: [String]; var isPrivate: Bool; var posterPath: String?; var currentTime: String
}

// MARK: - Flying Emoji Model
struct FlyingEmoji: Identifiable {
    let id = UUID(); let emoji: String; var offsetY: CGFloat = 0; var opacity: Double = 1; var xOffset: CGFloat
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
    @State private var showControls = true
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
    @State private var flyingEmojis: [FlyingEmoji] = []
    @State private var dominantColor: Color = Color(red: 0.05, green: 0.02, blue: 0.12)
    @State private var isLoadingEpisode = false
    @State private var isLoadingSeasons = false
    @State private var seasonError: String?
    @State private var posterImage: UIImage?
    @State private var refreshTimer: Timer?
    
    @State private var fakeRooms: [FakeRoom] = [
        FakeRoom(roomName: "Deadpool nè", movieTitle: "Deadpool & Wolverine", viewerCount: 6, avatars: ["🐱","🐶","🐰","🐻","🐼","🐨"], isPrivate: false, posterPath: "/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg", currentTime: "01:12:45"),
        FakeRoom(roomName: "kinh dị", movieTitle: "The Nun II", viewerCount: 3, avatars: ["🦊","🐸","🐵"], isPrivate: true, posterPath: "/5gzzkR7y3hnY8AD1wXjCnVlHba5.jpg", currentTime: "00:32:18"),
        FakeRoom(roomName: "⚡ Marvel Marathon", movieTitle: "Avengers: Endgame", viewerCount: 6, avatars: ["🐱","🐼","🐨","🐯","🦊","🐙"], isPrivate: false, posterPath: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", currentTime: "02:45:10"),
        FakeRoom(roomName: "Hàn xẻnggg ", movieTitle: "Parasite", viewerCount: 4, avatars: ["🐶","🐰","🐷","🐹"], isPrivate: false, posterPath: "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", currentTime: "01:05:33"),
        FakeRoom(roomName: "Rock & Movie", movieTitle: "Bohemian Rhapsody", viewerCount: 4, avatars: ["🐻","🐼","🐨","🐯"], isPrivate: true, posterPath: "/lHu1wtNaczFPgfDvJflLyh1HdxH.jpg", currentTime: "00:58:22"),
        FakeRoom(roomName: " cấm vào ", movieTitle: "Dune: Part Two", viewerCount: 5, avatars: ["🦊","🐸","🐵","🐮","🐷"], isPrivate: false, posterPath: "/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg", currentTime: "01:42:08"),
        FakeRoom(roomName: "babixinhiu ", movieTitle: "Deadpool 3", viewerCount: 6, avatars: ["🐹","🐭","🦄","🐙","🐱","🐶"], isPrivate: false, posterPath: "/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg", currentTime: "00:22:55"),
        FakeRoom(roomName: "ghost stories", movieTitle: "A Quiet Place", viewerCount: 3, avatars: ["🐰","🐻","🐼"], isPrivate: true, posterPath: "/nAU74GmpUk7t5iklEp3bufwDq4n.jpg", currentTime: "00:47:12"),
        FakeRoom(roomName: "🎥 Indie ", movieTitle: "Everything Everywhere", viewerCount: 2, avatars: ["🐨","🐯"], isPrivate: false, posterPath: "/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg", currentTime: "01:28:40"),
        FakeRoom(roomName: "🇯🇵 Animu", movieTitle: "Spirited Away", viewerCount: 4, avatars: ["🦊","🐸","🐵","🐮"], isPrivate: false, posterPath: "/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg", currentTime: "01:55:00"),
        FakeRoom(roomName: "🔥 Hot Hòn Họt", movieTitle: "John Wick 4", viewerCount: 5, avatars: ["🐷","🐹","🐭","🦄","🐙"], isPrivate: false, posterPath: "/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg", currentTime: "00:15:30"),
        FakeRoom(roomName: "Romcom", movieTitle: "How to Lose a Guy", viewerCount: 3, avatars: ["🐮","🐷","🐹"], isPrivate: false, posterPath: "/5gzzkR7y3hnY8AD1wXjCnVlHba5.jpg", currentTime: "00:38:55"),
    ]
    
    var displayTitle: String {
        if currentMovieTitle.isEmpty { return "Chọn phim" }
        var title = currentMovieTitle
        if let ep = selectedEpisode { title += " - S\(ep.seasonNumber):E\(ep.episodeNumber)" }
        return title
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if service.isInRoom { inRoomView }
            else if showCreateRoom { createRoomView }
            else { lobbyView }
            ForEach(flyingEmojis) { fe in Text(fe.emoji).font(.system(size: 32)).offset(y: fe.offsetY).offset(x: fe.xOffset).opacity(fe.opacity).allowsHitTesting(false) }
            if showEpisodePanel { episodePopupOverlay }
        }
        .onAppear { showControls = true; resetControlsTimer(); startFakeRoomRefresh()
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { n in if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect { keyboardHeight = frame.height } }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in keyboardHeight = 0 }
        }
        .onDisappear { refreshTimer?.invalidate(); controlsTimer?.invalidate(); forcePortrait() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in let o = UIDevice.current.orientation; isLandscape = o == .landscapeLeft || o == .landscapeRight }
        .onChange(of: service.isInRoom) { inRoom in if !inRoom { forcePortrait() } }
    }
    
    func forcePortrait() { guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }; ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)); isLandscape = false }
    func startFakeRoomRefresh() { refreshTimer = Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { _ in withAnimation(.easeInOut(duration: 0.5)) { for _ in 0..<3 { let idx = Int.random(in: 0..<fakeRooms.count); fakeRooms[idx].roomName = ["ai đoá ai đóa","gigi ngungục","ziku","Music & Movie","📺 Series Addict","bò cinema","newjeans neverdie","🔥 Trending Now","Hidden Gems","hanpham","🌴 Tropical Night","siu anh hùng"].randomElement() ?? fakeRooms[idx].roomName; fakeRooms[idx].movieTitle = ["Barbie","The Batman","Spider-Man","Joker","Inception","Tenet","Dunkirk","Memento","La La Land","Whiplash","Get Out","Us"].randomElement() ?? fakeRooms[idx].movieTitle; fakeRooms[idx].viewerCount = Int.random(in: 2...6); let m = Int.random(in: 0...120); let s = Int.random(in: 0...59); fakeRooms[idx].currentTime = String(format: "%02d:%02d:%02d", m/60, m, s) } } } }
    
    // MARK: - Lobby
    var lobbyView: some View { VStack(spacing: 0) { HStack { Text("Xem chung").font(.title2.bold()).foregroundColor(.white); Spacer(); Button { showCreateRoom = true } label: { Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundColor(.white) } }.padding(.horizontal, 20).padding(.top, 50).padding(.bottom, 16); ScrollView { VStack(spacing: 12) { ForEach(fakeRooms) { room in fakeRoomCard(room) } }.padding(.horizontal, 16).padding(.bottom, 120) } } }
    func fakeRoomCard(_ room: FakeRoom) -> some View { HStack(spacing: 12) { if let path = room.posterPath, let url = URL(string: "https://image.tmdb.org/t/p/w200\(path)") { CachedAsyncImage(url: url).aspectRatio(2/3, contentMode: .fill).frame(width: 64, height: 88).clipShape(RoundedRectangle(cornerRadius: 10)) } else { RoundedRectangle(cornerRadius: 10).fill(Material.ultraThinMaterial.opacity(0.35)).frame(width: 64, height: 88).overlay(Image(systemName: "play.circle.fill").font(.system(size: 22)).foregroundColor(.white.opacity(0.7))) }; VStack(alignment: .leading, spacing: 6) { Text(room.movieTitle).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1); Text(room.roomName).font(.system(size: 11)).foregroundColor(.gray).lineLimit(1); HStack(spacing: 8) { HStack(spacing: -8) { ForEach(room.avatars.prefix(4), id: \.self) { av in Text(av).font(.system(size: 10)).frame(width: 20, height: 20).background(Circle().fill(Material.ultraThinMaterial.opacity(0.6))) } }; Text("\(room.viewerCount) người").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)) } }; Spacer(); VStack(alignment: .trailing, spacing: 4) { Text("Đang xem").font(.system(size: 8)).foregroundColor(.green); Text(room.currentTime).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.7)) } }.padding(12).background(RoundedRectangle(cornerRadius: 18).fill(Material.ultraThinMaterial.opacity(0.22))).overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.06), lineWidth: 0.5)) }
    
    // MARK: - Create Room
    var createRoomView: some View { VStack(spacing: 24) { HStack { Button { showCreateRoom = false } label: { Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(Material.ultraThinMaterial.opacity(0.4))) }; Spacer(); Text("Tạo phòng").font(.title3.bold()).foregroundColor(.white); Spacer(); Circle().fill(.clear).frame(width: 44) }.padding(.horizontal, 16).padding(.top, 50); VStack(spacing: 16) { HStack { Text("Avatar của bạn:").font(.system(size: 13)).foregroundColor(.white.opacity(0.7)); Spacer(); Text(WatchTogetherService.defaultAvatars[abs((userName.isEmpty ? "guest" : userName).hashValue) % WatchTogetherService.defaultAvatars.count]).font(.system(size: 28)).frame(width: 44, height: 44).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5))).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5)) }.padding(.horizontal, 4); TextField("Tên của bạn", text: $userName).font(.system(size: 15)).foregroundColor(.white).padding(16).background(RoundedRectangle(cornerRadius: 16).fill(Material.ultraThinMaterial.opacity(0.25))); TextField("Tên phòng (tuỳ chọn)", text: $roomName).font(.system(size: 15)).foregroundColor(.white).padding(16).background(RoundedRectangle(cornerRadius: 16).fill(Material.ultraThinMaterial.opacity(0.25))); Button { guard !userName.isEmpty else { return }; service.createRoom(roomName: roomName.isEmpty ? "Phòng của \(userName)" : roomName, userName: userName) { _ in showCreateRoom = false } } label: { HStack { Image(systemName: "movieclapper.fill"); Text("Tạo phòng").font(.headline) }.foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(Capsule().fill(Material.ultraThinMaterial.opacity(0.5))) }; HStack(spacing: 12) { Rectangle().fill(.white.opacity(0.15)).frame(height: 1); Text("hoặc tham gia").font(.system(size: 11)).foregroundColor(.gray); Rectangle().fill(.white.opacity(0.15)).frame(height: 1) }; TextField("Nhập mã phòng 6 số", text: $joinCode).font(.system(size: 15)).foregroundColor(.white).padding(16).background(RoundedRectangle(cornerRadius: 16).fill(Material.ultraThinMaterial.opacity(0.25))).keyboardType(.numberPad); Button { guard !userName.isEmpty, joinCode.count == 6 else { return }; service.joinRoom(code: joinCode, userName: userName) { success, _ in if success { showCreateRoom = false } } } label: { HStack { Image(systemName: "arrow.right.circle.fill"); Text("Vào phòng").font(.headline) }.foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(Capsule().fill(Material.ultraThinMaterial.opacity(0.5))) } }.padding(.horizontal, 24); Spacer() }.background(Color.black.ignoresSafeArea()) }
    
    // MARK: - In Room
    var inRoomView: some View {
        GeometryReader { geo in
            if isLandscape {
    HStack(spacing: 0) {
        CustomPlayerVC(player: player, pipController: $pipController)
            .frame(width: geo.size.width * 0.65)
            .overlay { videoControlsOverlay }
            .onTapGesture { toggleControlsInRoom() }
        landscapeChatPanel
            .frame(width: geo.size.width * 0.35)
    }
}
            } else {
                VStack(spacing: 0) {
                    CustomPlayerVC(player: player, pipController: $pipController)
                        .frame(height: geo.size.width * 9 / 16)
                        .overlay { videoControlsOverlay }
                        .onTapGesture { toggleControlsInRoom() }
                    imessageChatPanel
                }
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.3), value: showControls)
        .sheet(isPresented: $showViewerPanel) { viewerPanel.presentationDetents([.medium]) }
        .sheet(isPresented: $showSearchMovie) { SearchView(onSelectMovie: { movie in loadMovieForRoom(movie) }) }
        .onAppear { player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { t in let newTime = t.seconds; if newTime.isFinite { currentTime = newTime }; if let d = player.currentItem?.duration, d.isNumeric, d.seconds.isFinite { duration = d.seconds } } }
        .onChange(of: service.remoteState?.timestamp) { _ in handleRemoteState() }
        .onChange(of: player.rate) { newRate in if service.isInRoom && service.isHost { service.sendPlaybackState(action: newRate > 0 ? "play" : "pause", time: currentTime) } }
    }
    
    var videoControlsOverlay: some View {
        Group { if showControls { VStack(spacing: 0) { HStack { Button { player.pause(); player.replaceCurrentItem(with: nil); service.leaveRoom() } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold)).foregroundColor(.white).padding(6).background(Circle().fill(.ultraThinMaterial.opacity(0.5))) }; Spacer(); Button { showEpisodePanel = true } label: { Text(displayTitle).font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1) }; Spacer(); Button { toggleOrientation() } label: { Image(systemName: "rotate.right").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(6).background(Circle().fill(.ultraThinMaterial.opacity(0.5))) } }.padding(.horizontal, 12).padding(.top, isLandscape ? 4 : 48); Spacer(); HStack(spacing: 36) { Button { seek(-10) } label: { Image(systemName: "gobackward.10").font(.system(size: 18)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.3))) }; Button { if player.rate == 0 { player.play() } else { player.pause() }; if service.isHost { service.sendPlaybackState(action: player.rate == 0 ? "play" : "pause", time: currentTime) } } label: { Image(systemName: player.rate == 0 ? "play.fill" : "pause.fill").font(.system(size: 22)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4))) }; Button { seek(10) } label: { Image(systemName: "goforward.10").font(.system(size: 18)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.3))) } }; Spacer() } } }
    }
    
    func handleRemoteState() { guard let state = service.remoteState, !service.isHost else { return }; let target = CMTime(seconds: state.time, preferredTimescale: 600); if let ep = state.episodeNumber, let sn = state.seasonNumber { if selectedEpisode?.episodeNumber != ep || selectedSeason?.seasonNumber != sn { Task { if let detail = try? await APIService.shared.fetchSeasonDetail(tvId: currentMovie?.id ?? 0, seasonNumber: sn), let episode = detail.episodes.first(where: { $0.episodeNumber == ep }) { await MainActor.run { selectedSeason = seasons.first(where: { $0.seasonNumber == sn }); selectedEpisode = episode; loadEpisode(episode) } } } } }; if state.action == "play" { player.seek(to: target); player.play() } else if state.action == "pause" { player.seek(to: target); player.pause() } else if state.action == "seek" { player.seek(to: target) } }
    func toggleOrientation() { guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }; ws.requestGeometryUpdate(.iOS(interfaceOrientations: isLandscape ? .portrait : .landscapeRight)) }
    func toggleControlsInRoom() { withAnimation(.easeInOut(duration: 0.25)) { showControls.toggle() }; controlsTimer?.invalidate(); if showControls { resetControlsTimer() } }
    func resetControlsTimer() { controlsTimer?.invalidate(); controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.3)) { showControls = false } } }
    
    // MARK: - Chat
    var imessageChatPanel: some View {
        VStack(spacing: 0) {
            HStack { VStack(alignment: .leading, spacing: 2) { Text(displayTitle).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1); Text(service.currentRoomName).font(.system(size: 10)).foregroundColor(.white.opacity(0.6)) }; Spacer(); HStack(spacing: 6) { Button { showSearchMovie = true } label: { Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundColor(.white).padding(6).background(Circle().fill(.ultraThinMaterial.opacity(0.5))) }; Button { showViewerPanel = true } label: { HStack(spacing: -4) { ForEach(service.participants.prefix(2), id: \.userId) { p in Text(p.avatar).font(.system(size: 9)).frame(width: 16, height: 16).background(Circle().fill(.ultraThinMaterial.opacity(0.4))) } }.padding(5).background(Capsule().fill(.ultraThinMaterial.opacity(0.5))) } } }
            .padding(.horizontal, 12).padding(.vertical, 6).background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 0.5))).padding(.horizontal, 8).padding(.top, 6)
            if duration > 0 { VStack(spacing: 2) { HStack { Text(formatTime(currentTime)).font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.5)); Spacer(); Text(formatTime(duration)).font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.5)) }; GeometryReader { g in ZStack(alignment: .leading) { Capsule().fill(.white.opacity(0.1)).frame(height: 3); Capsule().fill(.white.opacity(0.6)).frame(width: max(3, g.size.width * CGFloat(min(max(currentTime / max(duration, 1), 0), 1))), height: 3) } }.frame(height: 3) }.padding(.horizontal, 12).padding(.vertical, 4) }
            HStack(spacing: 20) { ForEach(["😭","🤣","👏","❤️","🔥","💀"], id: \.self) { e in Button { sendReaction(e) } label: { Text(e).font(.system(size: 20)) } } }.padding(.horizontal, 12).padding(.vertical, 4)
            ScrollViewReader { proxy in ScrollView { LazyVStack(spacing: 4) { Color.clear.frame(height: 2); ForEach(Array(service.messages.enumerated()), id: \.element.id) { idx, msg in imessageBubble(msg, showAvatar: shouldShowAvatar(at: idx)).id(msg.id) }; Color.clear.frame(height: 4) }.padding(.horizontal, 12) }.onChange(of: service.messages.count) { _ in if let last = service.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } } } }
            HStack(spacing: 10) { TextField("Nhắn tin...", text: $watchMessage).focused($isInputFocused).font(.system(size: 16)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 16).background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial.opacity(0.6)).overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12), lineWidth: 0.5))).onSubmit { sendImessage() }; if !watchMessage.isEmpty { Button { sendImessage() } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 34)).foregroundColor(.white) } } }
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 15 : 12)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .background(ZStack { if let img = posterImage { Image(uiImage: img).resizable().aspectRatio(contentMode: .fill).blur(radius: 80).opacity(0.25) }; dominantColor.opacity(0.15); Rectangle().fill(.regularMaterial) }).contentShape(Rectangle()).onTapGesture { isInputFocused = false }
    }
    
    func sendReaction(_ emoji: String) { let fe = FlyingEmoji(emoji: emoji, xOffset: CGFloat.random(in: -50...50)); flyingEmojis.append(fe); withAnimation(.easeOut(duration: 1.0)) { if let idx = flyingEmojis.firstIndex(where: { $0.id == fe.id }) { flyingEmojis[idx].offsetY = -100; flyingEmojis[idx].opacity = 0 } }; DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { flyingEmojis.removeAll { $0.id == fe.id } } }
    func shouldShowAvatar(at index: Int) -> Bool { if index == 0 { return true }; return service.messages[index].userId != service.messages[index - 1].userId }
    func imessageBubble(_ msg: WatchTogetherService.ChatMessage, showAvatar: Bool) -> some View { let isMe = msg.userId == service.userId; return HStack(alignment: .bottom, spacing: 6) { if !isMe { if showAvatar { Text(msg.avatar).font(.system(size: 16)).frame(width: 30, height: 30).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5))) } else { Color.clear.frame(width: 30, height: 30) } } else { Spacer() }; VStack(alignment: isMe ? .trailing : .leading, spacing: 2) { if showAvatar { Text(msg.userName).font(.system(size: 10)).foregroundColor(.white.opacity(0.5)) }; Text(msg.text).font(.system(size: 14)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 16).fill(Material.ultraThinMaterial.opacity(isMe ? 0.5 : 0.3))).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(isMe ? 0.15 : 0.08), lineWidth: 0.5)) }; if isMe { if showAvatar { Text(msg.avatar).font(.system(size: 16)).frame(width: 30, height: 30).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5))) } else { Color.clear.frame(width: 30, height: 30) } } else { Spacer() } } }
    func sendImessage() { let t = watchMessage.trimmingCharacters(in: .whitespaces); guard !t.isEmpty else { return }; service.sendMessage(text: t); watchMessage = ""; isInputFocused = false }
    func seek(_ s: Double) { let t = max(0, min(currentTime + s, duration)); player.seek(to: CMTime(seconds: t, preferredTimescale: 600)); currentTime = t; if service.isHost { service.sendPlaybackState(action: "seek", time: t) } }
    func formatTime(_ s: Double) -> String { let ts = Int(max(0, s)); let h = ts / 3600; let m = (ts % 3600) / 60; let sec = ts % 60; if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }; return String(format: "%02d:%02d", m, sec) }
    
    // MARK: - Load Movie
    func loadMovieForRoom(_ movie: Movie) { currentMovieTitle = movie.title; currentMovie = movie; selectedSeason = nil; episodes = []; selectedEpisode = nil; seasons = []; isLoadingSeasons = true; seasonError = nil; if let posterURL = movie.posterURL { Task { if let (data, _) = try? await URLSession.shared.data(from: posterURL), let img = UIImage(data: data) { await MainActor.run { posterImage = img } } } }; Task { let urlString = "https://api.themoviedb.org/3/tv/\(movie.id)?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US"; guard let url = URL(string: urlString) else { await MainActor.run { isLoadingSeasons = false }; return }; do { let (data, _) = try await URLSession.shared.data(from: url); struct TVDetailResponse: Codable { let seasons: [TVSeason]? }; let response = try JSONDecoder().decode(TVDetailResponse.self, from: data); let fetched = response.seasons?.filter { $0.seasonNumber > 0 } ?? []; await MainActor.run { self.seasons = fetched; self.isLoadingSeasons = false } } catch { if let fetched = try? await APIService.shared.fetchTVSeasons(tvId: movie.id) { await MainActor.run { self.seasons = fetched; self.isLoadingSeasons = false } } else { await MainActor.run { self.isLoadingSeasons = false; self.seasonError = error.localizedDescription } } } }; Task { do { let isTV = movie.mediaType == "tv"; let imdbID = try await fetchIMDBID(for: movie.id, mediaType: isTV ? "tv" : nil); var streamURL: URL?; streamURL = try? await withCheckedThrowingContinuation { c in PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: isTV ? "tv" : "movie", season: nil, episode: nil) { c.resume(with: $0) } }; if streamURL == nil { streamURL = try? await withCheckedThrowingContinuation { c in SofaflixService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: isTV ? "tv" : "movie", season: nil, episode: nil) { c.resume(with: $0) } } }; guard let url = streamURL else { return }; await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); if service.isHost { service.sendPlaybackState(action: "play", time: 0) } } } catch { print("Load error: \(error)") } } }
    func loadEpisode(_ ep: TVEpisode) { guard let movie = currentMovie else { return }; selectedEpisode = ep; isLoadingEpisode = true; Task { do { let imdbID = try await fetchIMDBID(for: movie.id, mediaType: movie.mediaType); var streamURL: URL?; streamURL = try? await withCheckedThrowingContinuation { c in PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: ep.seasonNumber, episode: ep.episodeNumber) { c.resume(with: $0) } }; if streamURL == nil { streamURL = try? await withCheckedThrowingContinuation { c in SofaflixService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: ep.seasonNumber, episode: ep.episodeNumber) { c.resume(with: $0) } } }; guard let url = streamURL else { await MainActor.run { isLoadingEpisode = false }; return }; await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); isLoadingEpisode = false; if service.isHost { service.sendPlaybackState(action: "play", time: 0) } } } catch { await MainActor.run { isLoadingEpisode = false } } } }
    func fetchIMDBID(for tmdbID: Int, mediaType: String?) async throws -> String { if mediaType == "tv", let id = try? await APIService.shared.fetchExternalIDs(tvId: tmdbID), !id.isEmpty { return id }; let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(tmdbID)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!); struct E: Codable { let imdb_id: String? }; guard let id = try JSONDecoder().decode(E.self, from: data).imdb_id, !id.isEmpty else { throw NSError(domain: "", code: -1) }; return id }
    
    // MARK: - Episode Popup
    var episodePopupOverlay: some View { ZStack { Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { showEpisodePanel = false }; VStack(spacing: 0) { HStack { Text("Chọn tập").font(.system(size: 17, weight: .bold)).foregroundColor(.white); Spacer(); Button { showEpisodePanel = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(.white.opacity(0.6)) } }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 12); if isLoadingEpisode || isLoadingSeasons { VStack(spacing: 12) { ProgressView().tint(.white); Text("Đang tải...").font(.system(size: 13)).foregroundColor(.gray) }.frame(height: 150) } else if seasons.isEmpty && episodes.isEmpty { VStack(spacing: 12) { Image(systemName: "tv.slash").font(.system(size: 36)).foregroundColor(.gray); Text(seasonError ?? "Phim lẻ hoặc chưa có dữ liệu").font(.system(size: 13)).foregroundColor(.gray).multilineTextAlignment(.center); Button { showEpisodePanel = false; showSearchMovie = true } label: { Text("Chọn phim khác").font(.system(size: 14)).foregroundColor(.blue) } }.frame(height: 150) } else if let selSeason = selectedSeason { VStack(alignment: .leading, spacing: 6) { Button { withAnimation { selectedSeason = nil; episodes = [] } } label: { HStack { Image(systemName: "chevron.left").font(.system(size: 11)); Text(selSeason.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white); Spacer() }.padding(.horizontal, 20).padding(.vertical, 8) }; Divider().background(.white.opacity(0.1)).padding(.horizontal, 20); ScrollView { LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) { ForEach(episodes) { ep in Button { selectedEpisode = ep; showEpisodePanel = false; loadEpisode(ep) } label: { Text("\(ep.episodeNumber)").font(.system(size: 14, weight: .medium)).foregroundColor(selectedEpisode?.id == ep.id ? .black : .white).frame(height: 38).frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 10).fill(selectedEpisode?.id == ep.id ? AnyShapeStyle(Color.white) : AnyShapeStyle(Material.ultraThinMaterial.opacity(0.3)))) } } }.padding(.horizontal, 20).padding(.top, 8) }.frame(maxHeight: 220) } } else { ScrollView { VStack(spacing: 8) { ForEach(seasons) { season in Button { withAnimation { selectedSeason = season; isLoadingEpisode = true; Task { do { let detail = try await APIService.shared.fetchSeasonDetail(tvId: currentMovie?.id ?? 0, seasonNumber: season.seasonNumber); await MainActor.run { episodes = detail.episodes; isLoadingEpisode = false } } catch { await MainActor.run { isLoadingEpisode = false } } } } } label: { HStack { Text(season.name).font(.system(size: 15)).foregroundColor(.white); Spacer(); Text("\(season.episodeCount) tập").font(.system(size: 12)).foregroundColor(.gray); Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(.gray) }.padding(.horizontal, 20).padding(.vertical, 13).background(RoundedRectangle(cornerRadius: 12).fill(Material.ultraThinMaterial.opacity(0.25))) } } }.padding(.horizontal, 16).padding(.vertical, 10) }.frame(maxHeight: 250) } }.frame(width: 320).background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15), lineWidth: 0.5))).shadow(color: .black.opacity(0.5), radius: 20) } }
    
    // MARK: - Panels
    var viewerPanel: some View { VStack(spacing: 0) { Capsule().fill(.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 10); Text("Người xem (\(service.participants.count))").font(.headline).foregroundColor(.white).padding(.vertical, 12); ScrollView { VStack(spacing: 12) { ForEach(service.participants, id: \.userId) { p in HStack(spacing: 12) { Text(p.avatar).font(.system(size: 28)).frame(width: 48, height: 48).background(Circle().fill(Material.ultraThinMaterial.opacity(0.4))).overlay(Circle().fill(p.isOnline ? Color.green : Color.gray).frame(width: 10, height: 10).offset(x: 17, y: 17)); VStack(alignment: .leading, spacing: 2) { Text(p.userName).font(.system(size: 14, weight: .medium)).foregroundColor(.white); Text(p.isOnline ? "Đang xem" : "Đã rời").font(.system(size: 11)).foregroundColor(.gray) }; Spacer() }.padding(.horizontal, 20) } } } }.background(Color.black.opacity(0.95)) }
}