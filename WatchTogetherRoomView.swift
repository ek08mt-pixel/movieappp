import SwiftUI
import AVKit

// MARK: - Fake Room Data for Lobby
struct FakeRoom: Identifiable {
    let id = UUID()
    let roomName: String
    let movieTitle: String
    let posterPath: String?
    let viewerCount: Int
    let avatars: [String]
}

// MARK: - Main Watch Together View
struct WatchTogetherRoomView: View {
    @StateObject private var service = WatchTogetherService.shared
    @State private var player = AVPlayer()
    @State private var currentTime: Double = 0
    @State private var showChat = true
    @State private var showViewerPanel = false
    @State private var watchMessage = ""
    @State private var userName = ""
    @State private var roomName = ""
    @State private var joinCode = ""
    @State private var showCreateRoom = false
    @State private var showSearchMovie = false
    
    // Fake rooms for lobby
    let fakeRooms: [FakeRoom] = [
        FakeRoom(roomName: "Phim kinh dị đêm", movieTitle: "The Conjuring", posterPath: nil, viewerCount: 4, avatars: ["🐱","🐶","🐰","🐻"]),
        FakeRoom(roomName: "Romantic night", movieTitle: "Titanic", posterPath: nil, viewerCount: 6, avatars: ["🦊","🐸","🐵","🐮","🐷","🐹"]),
        FakeRoom(roomName: "Anime fans", movieTitle: "Your Name", posterPath: nil, viewerCount: 3, avatars: ["🐭","🦄","🐙"]),
        FakeRoom(roomName: "Marathon Marvel", movieTitle: "Avengers: Endgame", posterPath: nil, viewerCount: 5, avatars: ["🐱","🐼","🐨","🐯","🦊"]),
        FakeRoom(roomName: "Hài cuối tuần", movieTitle: "Deadpool", posterPath: nil, viewerCount: 2, avatars: ["🐶","🐰"]),
        FakeRoom(roomName: "Sci-fi night", movieTitle: "Interstellar", posterPath: nil, viewerCount: 6, avatars: ["🐻","🐼","🐨","🐯","🦊","🐸"]),
    ]
    
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
    }
    
    // MARK: - Lobby View
    var lobbyView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Xem chung")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                Button {
                    showCreateRoom = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 14) {
                    if service.isInRoom {
                        realRoomCard
                    }
                    
                    ForEach(fakeRooms) { room in
                        fakeRoomCard(room)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    var realRoomCard: some View {
        Button {
            // Đã trong room, không cần action
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .frame(width: 60, height: 80)
                    .overlay(Image(systemName: "film").foregroundColor(.white))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(service.currentRoomName)
                        .font(.headline).foregroundColor(.white)
                    Text("Bạn đang trong phòng")
                        .font(.caption).foregroundColor(.gray)
                    HStack(spacing: -6) {
                        ForEach(service.participants.prefix(4), id: \.userId) { p in
                            Text(p.avatar).font(.system(size: 14))
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                        Text("+\(service.participants.count)")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.3)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 0.5))
        }
    }
    
    func fakeRoomCard(_ room: FakeRoom) -> some View {
        Button {
            // Fake room - hiện tại chỉ show
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .frame(width: 60, height: 80)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.roomName)
                        .font(.headline).foregroundColor(.white)
                    Text(room.movieTitle)
                        .font(.caption).foregroundColor(.gray)
                    HStack(spacing: -6) {
                        ForEach(room.avatars, id: \.self) { av in
                            Text(av).font(.system(size: 12))
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                        }
                        Text("\(room.viewerCount) người")
                            .font(.caption2).foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer()
                VStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Live").font(.system(size: 8)).foregroundColor(.green)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.25)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 0.5))
        }
    }
    
    // MARK: - Create Room View
    var createRoomView: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    showCreateRoom = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                }
                Spacer()
                Text("Tạo phòng").font(.headline).foregroundColor(.white)
                Spacer()
                Circle().fill(.clear).frame(width: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            
            VStack(spacing: 16) {
                TextField("Tên của bạn", text: $userName)
                    .font(.system(size: 14)).foregroundColor(.white)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.2)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5))
                
                TextField("Tên phòng", text: $roomName)
                    .font(.system(size: 14)).foregroundColor(.white)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.2)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5))
                
                Button {
                    guard !userName.isEmpty else { return }
                    service.createRoom(roomName: roomName.isEmpty ? "Phòng của \(userName)" : roomName, userName: userName) { _ in
                        showCreateRoom = false
                    }
                } label: {
                    Text("Tạo phòng")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.4)))
                        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                }
                
                HStack {
                    Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5)
                    Text("hoặc").font(.caption).foregroundColor(.gray)
                    Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5)
                }
                
                TextField("Nhập mã phòng", text: $joinCode)
                    .font(.system(size: 14)).foregroundColor(.white)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.2)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 0.5))
                    .keyboardType(.numberPad)
                
                Button {
                    guard !userName.isEmpty, joinCode.count == 6 else { return }
                    service.joinRoom(code: joinCode, userName: userName) { success, _ in
                        if success { showCreateRoom = false }
                    }
                } label: {
                    Text("Vào phòng")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.4)))
                        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - In Room View
    var inRoomView: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                if isLandscape {
                    CustomPlayerVC(player: player, pipController: .constant(nil))
                        .ignoresSafeArea()
                    
                    if showChat {
                        VStack {
                            Spacer()
                            chatOverlayPortrait
                                .frame(height: geo.size.height * 0.25)
                        }
                        .transition(.move(edge: .bottom))
                    }
                } else {
                    VStack(spacing: 0) {
                        CustomPlayerVC(player: player, pipController: .constant(nil))
                            .frame(height: geo.size.height * 0.5)
                        
                        chatOverlayPortrait
                            .frame(height: geo.size.height * 0.5)
                    }
                }
                
                VStack {
                    HStack {
                        Button {
                            service.leaveRoom()
                            player.pause()
                            player.replaceCurrentItem(with: nil)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                        Spacer()
                        Text(service.currentRoomName)
                            .font(.caption).foregroundColor(.white.opacity(0.8))
                        Spacer()
                        HStack(spacing: 6) {
                            Button { showSearchMovie = true } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 12)).foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                            Button { showViewerPanel = true } label: {
                                HStack(spacing: -4) {
                                    ForEach(service.participants.prefix(2), id: \.userId) { p in
                                        Text(p.avatar).font(.system(size: 10))
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                                    }
                                }
                                .padding(6)
                                .background(Capsule().fill(.ultraThinMaterial.opacity(0.4)))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 50)
                    Spacer()
                }
            }
            .animation(.spring(response: 0.35), value: showChat)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showViewerPanel) {
            viewerPanel
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSearchMovie) {
            SearchView(onSelectMovie: { movie in
                loadMovieForRoom(movie)
            })
        }
        .onChange(of: service.remoteState?.timestamp) { _ in
            guard let state = service.remoteState, !service.isHost else { return }
            let target = CMTime(seconds: state.time, preferredTimescale: 600)
            if state.action == "play" { player.seek(to: target); player.play() }
            else if state.action == "pause" { player.seek(to: target); player.pause() }
            else if state.action == "seek" { player.seek(to: target) }
        }
        .onChange(of: player.rate) { newRate in
            if service.isInRoom && service.isHost {
                service.sendPlaybackState(action: newRate > 0 ? "play" : "pause", time: currentTime)
            }
        }
    }
    
    // MARK: - Load Movie
    func loadMovieForRoom(_ movie: Movie) {
        Task {
            do {
                let imdbID = try await fetchIMDBID(for: movie.id, mediaType: movie.mediaType)
                let url = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                    PhimAPIService.shared.fetchStream(
                        imdbID: imdbID,
                        tmdbID: movie.id,
                        title: movie.title,
                        mediaType: movie.mediaType,
                        season: nil,
                        episode: nil
                    ) { result in
                        cont.resume(with: result)
                    }
                }
                await MainActor.run {
                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    player.play()
                    if service.isHost {
                        service.sendPlaybackState(action: "play", time: 0)
                    }
                }
            } catch {
                print("Load movie error: \(error)")
            }
        }
    }
    
    func fetchIMDBID(for tmdbID: Int, mediaType: String?) async throws -> String {
        if mediaType == "tv" {
            if let id = try? await APIService.shared.fetchExternalIDs(tvId: tmdbID), !id.isEmpty {
                return id
            }
        }
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.themoviedb.org/3/movie/\(tmdbID)/external_ids?api_key=b6be36c1c5788565fec6a24811e7cc9b")!)
        struct E: Codable { let imdb_id: String? }
        let imdb = try JSONDecoder().decode(E.self, from: data).imdb_id
        guard let id = imdb, !id.isEmpty else { throw NSError(domain: "", code: -1) }
        return id
    }
    
    // MARK: - Chat Overlay
    var chatOverlayPortrait: some View {
        VStack(spacing: 0) {
            let msgs = service.messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(msgs) { msg in
                            inRoomChatBubble(msg).id(msg.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .onChange(of: msgs.count) { _ in
                    if let last = msgs.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            
            HStack(spacing: 6) {
                TextField("Nhắn tin...", text: $watchMessage)
                    .font(.system(size: 13)).foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(.ultraThinMaterial.opacity(0.3)))
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                    .onSubmit { sendInRoomMessage() }
                
                Button { sendInRoomMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(watchMessage.isEmpty ? .white.opacity(0.2) : .white)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial.opacity(0.6))
    }
    
    func inRoomChatBubble(_ msg: WatchTogetherService.ChatMessage) -> some View {
        HStack(spacing: 6) {
            Text(msg.avatar).font(.system(size: 12))
                .frame(width: 22, height: 22)
                .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(msg.userName)
                    .font(.system(size: 8)).foregroundColor(.white.opacity(0.6))
                Text(msg.text)
                    .font(.system(size: 12)).foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04)))
    }
    
    func sendInRoomMessage() {
        let trimmed = watchMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        service.sendMessage(text: trimmed)
        watchMessage = ""
    }
    
    // MARK: - Viewer Panel
    var viewerPanel: some View {
        VStack(spacing: 0) {
            Capsule().fill(.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 10)
            Text("Người xem (\(service.participants.count))")
                .font(.headline).foregroundColor(.white).padding(.vertical, 12)
            
            let parts = service.participants
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(parts, id: \.userId) { p in
                        HStack(spacing: 12) {
                            Text(p.avatar).font(.system(size: 28))
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(
                                    Circle().fill(p.isOnline ? Color.green : Color.gray)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 17, y: 17)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.userName).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                                Text(p.isOnline ? "Đang xem" : "Đã rời").font(.system(size: 11)).foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.95))
    }
}