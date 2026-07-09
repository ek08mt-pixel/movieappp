import SwiftUI
import AVKit

struct WatchTogetherRoomView: View {
    @StateObject private var watchService = WatchTogetherService.shared
    @State private var showSetup = false
    @State private var watchUserName = ""
    @State private var watchRoomName = ""
    @State private var watchMessage = ""
    @State private var joinCode = ""
    @State private var joinError = ""
    @State private var showChat = true
    @State private var player = AVPlayer()
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if watchService.isInRoom {
                GeometryReader { geo in
                    let isLandscape = geo.size.width > geo.size.height
                    
                    if isLandscape {
                        HStack(spacing: 0) {
                            CustomPlayerVC(player: player, pipController: .constant(nil))
                                .frame(width: showChat ? geo.size.width * 0.65 : geo.size.width)
                                .animation(.spring(response: 0.35), value: showChat)
                            
                            if showChat {
                                chatPanel
                                    .frame(width: geo.size.width * 0.35)
                                    .transition(.move(edge: .trailing))
                            }
                        }
                    } else {
                        VStack(spacing: 0) {
                            CustomPlayerVC(player: player, pipController: .constant(nil))
                                .frame(height: showChat ? geo.size.height * 0.55 : geo.size.height)
                                .animation(.spring(response: 0.35), value: showChat)
                            
                            if showChat {
                                chatPanel
                                    .frame(height: geo.size.height * 0.45)
                                    .transition(.move(edge: .bottom))
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Xem phim cùng bạn bè")
                        .font(.title2).foregroundColor(.white)
                    Text("Tạo phòng hoặc nhập mã để tham gia")
                        .font(.subheadline).foregroundColor(.gray)
                    Button {
                        showSetup = true
                    } label: {
                        Text("Bắt đầu")
                            .font(.headline).foregroundColor(.white)
                            .padding(.horizontal, 40).padding(.vertical, 14)
                            .background(Capsule().fill(.ultraThinMaterial))
                            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                    }
                }
            }
            
            if watchService.isInRoom {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Button { showChat.toggle() } label: {
                                Image(systemName: showChat ? "message.fill" : "message")
                                    .font(.system(size: 12)).foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                            }
                            Button {
                                watchService.leaveRoom()
                                player.pause()
                                player.replaceCurrentItem(with: nil)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(.red.opacity(0.3)))
                            }
                        }
                        .padding(.trailing, 12)
                    }
                    .padding(.top, 50)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSetup) {
            setupSheet
        }
        .onDisappear {
            if watchService.isInRoom { watchService.leaveRoom() }
            player.pause()
        }
        .onChange(of: watchService.remoteState?.timestamp) { _ in
            guard let state = watchService.remoteState, !watchService.isHost else { return }
            let target = CMTime(seconds: state.time, preferredTimescale: 600)
            if state.action == "play" { player.seek(to: target); player.play() }
            else if state.action == "pause" { player.seek(to: target); player.pause() }
            else if state.action == "seek" { player.seek(to: target) }
        }
        .onChange(of: player.rate) { newRate in
            if watchService.isInRoom && watchService.isHost {
                watchService.sendPlaybackState(action: newRate > 0 ? "play" : "pause", time: currentTime)
            }
        }
    }
    
    var chatPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text(watchService.currentRoomName)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                Spacer()
                Text("#\(watchService.currentRoomCode)")
                    .font(.system(size: 10)).foregroundColor(.gray)
                Text("\(watchService.participants.count)/6")
                    .font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            
            Divider().background(.white.opacity(0.1))
            
            let parts = watchService.participants
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(parts, id: \.userId) { p in
                        VStack(spacing: 4) {
                            Text(p.avatar).font(.system(size: 24))
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(
                                    Circle().fill(p.isOnline ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 14, y: 14)
                                )
                            Text(p.userName).font(.system(size: 9)).foregroundColor(.white).lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
            }
            
            Divider().background(.white.opacity(0.1))
            
            let msgs = watchService.messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(msgs) { msg in
                            chatBubble(msg).id(msg.id)
                        }
                    }
                    .padding(8)
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
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(.white.opacity(0.08)))
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                    .onSubmit { sendMessage() }
                Button { sendMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(watchMessage.isEmpty ? .white.opacity(0.2) : .white)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
        }
        .background(.ultraThinMaterial.opacity(0.9))
    }
    
    func chatBubble(_ msg: WatchTogetherService.ChatMessage) -> some View {
        let isMe = msg.userId == watchService.userId
        return HStack(alignment: .top, spacing: 6) {
            if isMe { Spacer(minLength: 40) }
            Text(msg.avatar).font(.system(size: 14))
                .frame(width: 26, height: 26)
                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(msg.userName).font(.system(size: 9)).foregroundColor(.gray)
                Text(msg.text).font(.system(size: 12)).foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(isMe ? 0.12 : 0.06)))
            }
            if !isMe { Spacer(minLength: 40) }
        }
    }
    
    func sendMessage() {
        let trimmed = watchMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        watchService.sendMessage(text: trimmed)
        watchMessage = ""
    }
    
    var setupSheet: some View {
        VStack(spacing: 16) {
            Capsule().fill(.gray.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 10)
            Text("Xem chung").font(.title3.bold()).foregroundColor(.white)
            
            TextField("Tên của bạn", text: $watchUserName)
                .font(.system(size: 14)).foregroundColor(.white).padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 0.5))
            
            TextField("Tên phòng", text: $watchRoomName)
                .font(.system(size: 14)).foregroundColor(.white).padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 0.5))
            
            Button {
                guard !watchUserName.isEmpty else { return }
                watchService.createRoom(roomName: watchRoomName.isEmpty ? "Phòng của \(watchUserName)" : watchRoomName, userName: watchUserName) { _ in
                    showSetup = false
                }
            } label: {
                Text("Tạo phòng").font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
            }
            
            HStack {
                Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5)
                Text("hoặc").font(.caption).foregroundColor(.gray)
                Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5)
            }
            
            TextField("Mã phòng", text: $joinCode)
                .font(.system(size: 14)).foregroundColor(.white).padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 0.5))
                .keyboardType(.numberPad)
            
            if !joinError.isEmpty { Text(joinError).font(.caption).foregroundColor(.red) }
            
            Button {
                guard !watchUserName.isEmpty, joinCode.count == 6 else { return }
                watchService.joinRoom(code: joinCode, userName: watchUserName) { success, _ in
                    if success { showSetup = false; joinError = "" }
                    else { joinError = "Mã phòng không đúng" }
                }
            } label: {
                Text("Vào phòng").font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.95))
        .presentationDetents([.medium, .large])
    }
}