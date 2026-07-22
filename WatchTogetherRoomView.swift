import SwiftUI
import AVKit

// MARK: - Watch Player VC
struct WatchPlayerVC: UIViewControllerRepresentable {
    let player: AVPlayer
    @Binding var pipController: AVPictureInPictureController?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspect
        return vc
    }
    
    func updateUIViewController(_ ui: AVPlayerViewController, context: Context) {}
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
    @State private var isLoadingEpisode = false
    @State private var isLoadingSeasons = false
    @State private var seasonError: String?
    @State private var posterImage: UIImage?
    @State private var isJoining = false
    @State private var joinError: String?
    @State private var showJoinError = false
    
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
            else { lobbyView }
            ForEach(flyingEmojis) { fe in Text(fe.emoji).font(.system(size: 32)).offset(y: fe.offsetY).offset(x: fe.xOffset).opacity(fe.opacity).allowsHitTesting(false) }
            if showEpisodePanel { episodePopupOverlay }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear { showControls = true; resetControlsTimer()
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { n in if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect { keyboardHeight = frame.height } }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in keyboardHeight = 0 }
        }
        .onDisappear { controlsTimer?.invalidate(); forcePortrait() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in let o = UIDevice.current.orientation; isLandscape = o == .landscapeLeft || o == .landscapeRight }
        .onChange(of: service.isInRoom) { inRoom in if !inRoom { forcePortrait() } }
    }
    
    func forcePortrait() { guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }; ws.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)); isLandscape = false }
    
    // MARK: - Lobby
    var lobbyView: some View {
        ZStack {
            // Background xám đen
            Color(red: 0.06, green: 0.06, blue: 0.08)
                .ignoresSafeArea()
            
            // Lớp noise nhẹ
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.15))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                VStack(spacing: 4) {
                    Text("EMMEW")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Xem cùng bạn bè, mọi lúc mọi nơi")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(1.5)
                }
                .padding(.bottom, 44)
                
                // Card liquid glass
                VStack(spacing: 24) {
                    // Tạo phòng
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "sparkle")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                            Text("TẠO PHÒNG")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.35))
                                .tracking(2.5)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "film")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.3))
                                TextField("Tên phòng...", text: $roomName)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
                            )
                            
                            Button {
                                let name = roomName.trimmingCharacters(in: .whitespaces)
                                let finalName = name.isEmpty ? "Phòng \(Int.random(in: 100...999))" : name
                                let userName = appState.nickname.isEmpty ? "User" : appState.nickname
service.createRoom(roomName: finalName, userName: userName, avatar: appState.selectedAvatar) { _ in }
                                roomName = ""
                                isInputFocused = false
                            } label: {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(.white)
                                    )
                            }
                        }
                    }
                    
                    // Divider
                    HStack(spacing: 14) {
                        Rectangle()
                            .fill(.white.opacity(0.06))
                            .frame(height: 0.5)
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 3, height: 3)
                        Rectangle()
                            .fill(.white.opacity(0.06))
                            .frame(height: 0.5)
                    }
                    
                    // Tham gia phòng
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "key")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                            Text("THAM GIA BẰNG MÃ")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.35))
                                .tracking(2.5)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "number")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.3))
                                TextField("Mã 6 chữ số...", text: $joinCode)
                                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                                    .onChange(of: joinCode) { newVal in
                                        joinCode = String(newVal.filter { $0.isNumber }.prefix(6))
                                        joinError = nil
                                    }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(joinError != nil ? Color.red.opacity(0.4) : .white.opacity(0.08), lineWidth: 0.5)
                            )
                            
                            Button {
                                joinRoom()
                            } label: {
                                if isJoining {
                                    ProgressView()
                                        .tint(.black)
                                        .frame(width: 44, height: 44)
                                } else {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(.white.opacity(joinCode.count < 6 ? 0.3 : 1.0))
                                        )
                                }
                            }
                            .disabled(joinCode.count < 6 || isJoining)
                        }
                        
                        // Error
                        if let error = joinError {
                            HStack(spacing: 5) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 10))
                                Text(error)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.25))
                            .padding(.horizontal, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(.ultraThinMaterial.opacity(0.25))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.12), .white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 30, y: 15)
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .contentShape(Rectangle())
        .onTapGesture { isInputFocused = false }
    }
    
    func joinRoom() {
        let code = joinCode.trimmingCharacters(in: .whitespaces)
        guard code.count == 6 else {
            withAnimation(.easeOut(duration: 0.2)) { joinError = "Mã phòng phải có đúng 6 chữ số" }
            return
        }
        isJoining = true
        joinError = nil
        let userName2 = appState.nickname.isEmpty ? "User" : appState.nickname
service.joinRoom(code: code, userName: userName2, avatar: appState.selectedAvatar) { success, error in }
            isJoining = false
            if success {
                joinCode = ""
                isInputFocused = false
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    joinError = "Không tìm thấy phòng. Kiểm tra lại mã nhé!"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { joinError = nil }
                }
            }
        }
    }
    
    // MARK: - In Room
    var inRoomView: some View {
        GeometryReader { geo in
            if isLandscape {
                WatchPlayerVC(player: player, pipController: $pipController)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(videoControlsOverlay.allowsHitTesting(showControls))
                    .onTapGesture { toggleControlsInRoom() }
            } else {
                VStack(spacing: 0) {
                    WatchPlayerVC(player: player, pipController: $pipController)
                        .frame(height: geo.size.width * 9 / 16 - 45)
                        .overlay(videoControlsOverlay.allowsHitTesting(showControls))
                        .onTapGesture { toggleControlsInRoom() }
                    imessageChatPanel
                }
            }
        }
        .sheet(isPresented: $showViewerPanel) { viewerPanel.presentationDetents([.medium]) }
        .sheet(isPresented: $showSearchMovie) { SearchView(onSelectMovie: { movie in loadMovieForRoom(movie) }) }
        .onAppear { player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { t in let newTime = t.seconds; if newTime.isFinite { currentTime = newTime }; if let d = player.currentItem?.duration, d.isNumeric, d.seconds.isFinite { duration = d.seconds } } }
        .onChange(of: service.remoteState?.timestamp) { _ in handleRemoteState() }
        .onChange(of: player.rate) { newRate in if service.isInRoom && service.isHost { service.sendPlaybackState(action: newRate > 0 ? "play" : "pause", time: currentTime) } }
    }
    
    // MARK: - Video Controls
    var videoControlsOverlay: some View {
        ZStack {
            Color.black.opacity(0.001)
            if showControls {
                VStack(spacing: 0) {
                    HStack {
                        Button { if isLandscape { forcePortrait() } else { player.pause(); player.replaceCurrentItem(with: nil); service.leaveRoom() } } label: {
                            Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold)).foregroundColor(.white).padding(6).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                        Spacer()
                        Button { showEpisodePanel = true } label: { Text(displayTitle).font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1) }
                        Spacer()
                        Button { toggleOrientation() } label: {
                            Image(systemName: "rotate.right").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(6).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                    }
                    .padding(.horizontal, 12).padding(.top, isLandscape ? 12 : 50)
                    Spacer()
                    HStack(spacing: 36) {
                        Button { seek(-10) } label: { Image(systemName: "gobackward.10").font(.system(size: 18)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.3))) }
                        Button { if player.rate == 0 { player.play() } else { player.pause() }; if service.isHost { service.sendPlaybackState(action: player.rate == 0 ? "play" : "pause", time: currentTime) } } label: { Image(systemName: player.rate == 0 ? "play.fill" : "pause.fill").font(.system(size: 22)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4))) }
                        Button { seek(10) } label: { Image(systemName: "goforward.10").font(.system(size: 18)).foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.3))) }
                    }
                    .padding(.bottom, isLandscape ? 20 : 60)
                    Spacer()
                }
            }
        }
    }
    
    func handleRemoteState() { guard let state = service.remoteState, !service.isHost else { return }; let target = CMTime(seconds: state.time, preferredTimescale: 600); if let ep = state.episodeNumber, let sn = state.seasonNumber { if selectedEpisode?.episodeNumber != ep || selectedSeason?.seasonNumber != sn { Task { if let detail = try? await APIService.shared.fetchSeasonDetail(tvId: currentMovie?.id ?? 0, seasonNumber: sn), let episode = detail.episodes.first(where: { $0.episodeNumber == ep }) { await MainActor.run { selectedSeason = seasons.first(where: { $0.seasonNumber == sn }); selectedEpisode = episode; loadEpisode(episode) } } } } }; if state.action == "play" { player.seek(to: target); player.play() } else if state.action == "pause" { player.seek(to: target); player.pause() } else if state.action == "seek" { player.seek(to: target) } }
    func toggleOrientation() { guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }; ws.requestGeometryUpdate(.iOS(interfaceOrientations: isLandscape ? .portrait : .landscapeRight)) }
    func toggleControlsInRoom() { withAnimation(.easeInOut(duration: 0.25)) { showControls.toggle() }; controlsTimer?.invalidate(); if showControls { resetControlsTimer() } }
    func resetControlsTimer() { controlsTimer?.invalidate(); controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { _ in withAnimation(.easeInOut(duration: 0.3)) { showControls = false } } }
    
    // MARK: - Chat
    var imessageChatPanel: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayTitle).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Text("\(service.currentRoomName) • Mã: \(service.currentRoomCode)").font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                HStack(spacing: 6) {
                    Button { showSearchMovie = true } label: {
                        Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundColor(.white).padding(6).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                    }
                    Button { showViewerPanel = true } label: {
                        HStack(spacing: -4) {
                            ForEach(service.participants.prefix(2), id: \.userId) { p in
                                Text(p.avatar).font(.system(size: 9)).frame(width: 16, height: 16).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                        }
                        .padding(5).background(Capsule().fill(.ultraThinMaterial.opacity(0.5)))
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 0.5)))
            .padding(.horizontal, 8).padding(.top, 4)
            
            if duration > 0 {
                VStack(spacing: 2) {
                    HStack { Text(formatTime(currentTime)).font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.5)); Spacer(); Text(formatTime(duration)).font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.5)) }
                    GeometryReader { g in ZStack(alignment: .leading) { Capsule().fill(.white.opacity(0.1)).frame(height: 3); Capsule().fill(.white.opacity(0.6)).frame(width: max(3, g.size.width * CGFloat(min(max(currentTime / max(duration, 1), 0), 1))), height: 3) } }.frame(height: 3)
                }.padding(.horizontal, 12).padding(.vertical, 4)
            }
            
            HStack(spacing: 20) { ForEach(["😭","🥹","🤡","😻","🫢","🤯"], id: \.self) { e in Button { sendReaction(e) } label: { Text(e).font(.system(size: 20)) } } }.padding(.horizontal, 12).padding(.vertical, 4)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        Color.clear.frame(height: 2)
                        ForEach(Array(service.messages.enumerated()), id: \.element.id) { idx, msg in
                            imessageBubble(msg, showAvatar: shouldShowAvatar(at: idx)).id(msg.id)
                        }
                        Color.clear.frame(height: 4)
                    }.padding(.horizontal, 12)
                }
                .onChange(of: service.messages.count) { _ in if let last = service.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } } }
            }
            
            HStack(spacing: 10) {
                TextField("Nhắn tin...", text: $watchMessage).focused($isInputFocused).font(.system(size: 16)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 16).background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial.opacity(0.6)).overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12), lineWidth: 0.5))).onSubmit { sendImessage() }
                if !watchMessage.isEmpty { Button { sendImessage() } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 34)).foregroundColor(.white) } }
            }
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 5 : 20)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .background(Color.black).contentShape(Rectangle()).onTapGesture { isInputFocused = false }
    }
    
    func sendReaction(_ emoji: String) { let fe = FlyingEmoji(emoji: emoji, xOffset: CGFloat.random(in: -50...50)); flyingEmojis.append(fe); withAnimation(.easeOut(duration: 1.0)) { if let idx = flyingEmojis.firstIndex(where: { $0.id == fe.id }) { flyingEmojis[idx].offsetY = -100; flyingEmojis[idx].opacity = 0 } }; DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { flyingEmojis.removeAll { $0.id == fe.id } } }
    func shouldShowAvatar(at index: Int) -> Bool { if index == 0 { return true }; return service.messages[index].userId != service.messages[index - 1].userId }
    func imessageBubble(_ msg: WatchTogetherService.ChatMessage, showAvatar: Bool) -> some View { let isMe = msg.userId == service.userId; return HStack(alignment: .bottom, spacing: 6) { if !isMe { if showAvatar { Text(msg.avatar).font(.system(size: 16)).frame(width: 30, height: 30).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5))) } else { Color.clear.frame(width: 30, height: 30) } } else { Spacer() }; VStack(alignment: isMe ? .trailing : .leading, spacing: 2) { if showAvatar { Text(msg.userName).font(.system(size: 10)).foregroundColor(.white.opacity(0.5)) }; Text(msg.text).font(.system(size: 14)).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 16).fill(Material.ultraThinMaterial.opacity(isMe ? 0.5 : 0.3))).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(isMe ? 0.15 : 0.08), lineWidth: 0.5)) }; if isMe { if showAvatar { Text(msg.avatar).font(.system(size: 16)).frame(width: 30, height: 30).background(Circle().fill(Material.ultraThinMaterial.opacity(0.5))) } else { Color.clear.frame(width: 30, height: 30) } } else { Spacer() } } }
    func sendImessage() { let t = watchMessage.trimmingCharacters(in: .whitespaces); guard !t.isEmpty else { return }; service.sendMessage(text: t); watchMessage = ""; isInputFocused = false }
    func seek(_ s: Double) { let t = max(0, min(currentTime + s, duration)); player.seek(to: CMTime(seconds: t, preferredTimescale: 600)); currentTime = t; if service.isHost { service.sendPlaybackState(action: "seek", time: t) } }
    func formatTime(_ s: Double) -> String { let ts = Int(max(0, s)); let h = ts / 3600; let m = (ts % 3600) / 60; let sec = ts % 60; if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }; return String(format: "%02d:%02d", m, sec) }
    
    // MARK: - Load Movie
    func loadMovieForRoom(_ movie: Movie) { currentMovieTitle = movie.title; currentMovie = movie; selectedSeason = nil; episodes = []; selectedEpisode = nil; seasons = []; isLoadingSeasons = true; seasonError = nil; if let posterURL = movie.posterURL { Task { if let (data, _) = try? await URLSession.shared.data(from: posterURL), let img = UIImage(data: data) { await MainActor.run { posterImage = img } } } }; Task { let urlString = "https://api.themoviedb.org/3/tv/\(movie.id)?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=en-US"; guard let url = URL(string: urlString) else { await MainActor.run { isLoadingSeasons = false }; return }; do { let (data, _) = try await URLSession.shared.data(from: url); struct TVDetailResponse: Codable { let seasons: [TVSeason]? }; let response = try JSONDecoder().decode(TVDetailResponse.self, from: data); let fetched = response.seasons?.filter { $0.seasonNumber > 0 } ?? []; await MainActor.run { self.seasons = fetched; self.isLoadingSeasons = false } } catch { if let fetched = try? await APIService.shared.fetchTVSeasons(tvId: movie.id) { await MainActor.run { self.seasons = fetched; self.isLoadingSeasons = false } } else { await MainActor.run { self.isLoadingSeasons = false; self.seasonError = error.localizedDescription } } } }; Task { do { let isTV = movie.mediaType == "tv"; let imdbID = try await fetchIMDBID(for: movie.id, mediaType: isTV ? "tv" : nil); var streamURL: URL?; let phimResult = try? await withCheckedThrowingContinuation { c in PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: isTV ? "tv" : "movie", season: nil, episode: nil) { c.resume(with: $0) } }; streamURL = phimResult?.0
guard let url = streamURL else { return }
await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); if service.isHost { service.sendPlaybackState(action: "play", time: 0) } }
} catch { print("Load error: \(error)") } } }

    func loadEpisode(_ ep: TVEpisode) { guard let movie = currentMovie else { return }; selectedEpisode = ep; isLoadingEpisode = true; Task { do { let imdbID = try await fetchIMDBID(for: movie.id, mediaType: movie.mediaType); var streamURL: URL?; let phimResult = try? await withCheckedThrowingContinuation { c in PhimAPIService.shared.fetchStream(imdbID: imdbID, tmdbID: movie.id, title: movie.title, mediaType: movie.mediaType, season: ep.seasonNumber, episode: ep.episodeNumber) { c.resume(with: $0) } }; streamURL = phimResult?.0
guard let url = streamURL else { await MainActor.run { isLoadingEpisode = false }; return }
await MainActor.run { player.replaceCurrentItem(with: AVPlayerItem(url: url)); player.play(); isLoadingEpisode = false; if service.isHost { service.sendPlaybackState(action: "play", time: 0) } }
} catch { await MainActor.run { isLoadingEpisode = false } } } }

    func fetchIMDBID(for tmdbID: Int, mediaType: String?) async throws -> String { if mediaType == "tv", let id = try? await APIService.shared.fetchExternalIDs(tvId: tmdbID), !id.isEmpty { return id }; let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(tmdbID)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!); struct E: Codable { let imdb_id: String? }; guard let id = try JSONDecoder().decode(E.self, from: data).imdb_id, !id.isEmpty else { throw NSError(domain: "", code: -1) }; return id }
    
    // MARK: - Episode Popup
    var episodePopupOverlay: some View { ZStack { Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { showEpisodePanel = false }; VStack(spacing: 0) { HStack { Text("Chọn tập").font(.system(size: 17, weight: .bold)).foregroundColor(.white); Spacer(); Button { showEpisodePanel = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(.white.opacity(0.6)) } }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 12); if isLoadingEpisode || isLoadingSeasons { VStack(spacing: 12) { ProgressView().tint(.white); Text("Đang tải...").font(.system(size: 13)).foregroundColor(.gray) }.frame(height: 150) } else if seasons.isEmpty && episodes.isEmpty { VStack(spacing: 12) { Image(systemName: "tv.slash").font(.system(size: 36)).foregroundColor(.gray); Text(seasonError ?? "Phim lẻ hoặc chưa có dữ liệu").font(.system(size: 13)).foregroundColor(.gray).multilineTextAlignment(.center); Button { showEpisodePanel = false; showSearchMovie = true } label: { Text("Chọn phim khác").font(.system(size: 14)).foregroundColor(.blue) } }.frame(height: 150) } else if let selSeason = selectedSeason { VStack(alignment: .leading, spacing: 6) { Button { withAnimation { selectedSeason = nil; episodes = [] } } label: { HStack { Image(systemName: "chevron.left").font(.system(size: 11)); Text(selSeason.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white); Spacer() }.padding(.horizontal, 20).padding(.vertical, 8) }; Divider().background(.white.opacity(0.1)).padding(.horizontal, 20); ScrollView { LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) { ForEach(episodes) { ep in Button { selectedEpisode = ep; showEpisodePanel = false; loadEpisode(ep) } label: { Text("\(ep.episodeNumber)").font(.system(size: 14, weight: .medium)).foregroundColor(selectedEpisode?.id == ep.id ? .black : .white).frame(height: 38).frame(maxWidth: .infinity).background(RoundedRectangle(cornerRadius: 10).fill(selectedEpisode?.id == ep.id ? AnyShapeStyle(Color.white) : AnyShapeStyle(Material.ultraThinMaterial.opacity(0.3)))) } } }.padding(.horizontal, 20).padding(.top, 8) }.frame(maxHeight: 220) } } else { ScrollView { VStack(spacing: 8) { ForEach(seasons) { season in Button { withAnimation { selectedSeason = season; isLoadingEpisode = true; Task { do { let detail = try await APIService.shared.fetchSeasonDetail(tvId: currentMovie?.id ?? 0, seasonNumber: season.seasonNumber); await MainActor.run { episodes = detail.episodes; isLoadingEpisode = false } } catch { await MainActor.run { isLoadingEpisode = false } } } } } label: { HStack { Text(season.name).font(.system(size: 15)).foregroundColor(.white); Spacer(); Text("\(season.episodeCount) tập").font(.system(size: 12)).foregroundColor(.gray); Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(.gray) }.padding(.horizontal, 20).padding(.vertical, 13).background(RoundedRectangle(cornerRadius: 12).fill(Material.ultraThinMaterial.opacity(0.25))) } } }.padding(.horizontal, 16).padding(.vertical, 10) }.frame(maxHeight: 250) } }.frame(width: 320).background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15), lineWidth: 0.5))).shadow(color: .black.opacity(0.5), radius: 20) } }
    
    // MARK: - Panels
    var viewerPanel: some View { VStack(spacing: 0) { Capsule().fill(.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 10); Text("Người xem (\(service.participants.count))").font(.headline).foregroundColor(.white).padding(.vertical, 12); ScrollView { VStack(spacing: 12) { ForEach(service.participants, id: \.userId) { p in HStack(spacing: 12) { Text(p.avatar).font(.system(size: 28)).frame(width: 48, height: 48).background(Circle().fill(Material.ultraThinMaterial.opacity(0.4))).overlay(Circle().fill(p.isOnline ? Color.green : Color.gray).frame(width: 10, height: 10).offset(x: 17, y: 17)); VStack(alignment: .leading, spacing: 2) { Text(p.userName).font(.system(size: 14, weight: .medium)).foregroundColor(.white); Text(p.isOnline ? "Đang xem" : "Đã rời").font(.system(size: 11)).foregroundColor(.gray) }; Spacer() }.padding(.horizontal, 20) } } } }.background(Color.black.opacity(0.95)) }
}