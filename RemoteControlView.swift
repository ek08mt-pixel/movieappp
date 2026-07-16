import SwiftUI
import AVKit

// MARK: - Remote Control View
struct RemoteControlView: View {
    let movieTitle: String
    let episodeInfo: String
    var posterURL: URL?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 5400 // 90 phút demo
    @State private var isPlaying = true
    @State private var volume: Float = 0.5
    @State private var showInfo = false
    @State private var infoOpacity: Double = 0
    @State private var selectedAudio = "Vietsub"
    @State private var showAudioMenu = false
    
    // Demo timer
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.04), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .overlay(.ultraThinMaterial.opacity(0.05))
            
            VStack(spacing: 0) {
                // Status bar
                HStack {
                    // Đèn hiệu cast
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .fill(Color.green.opacity(0.4))
                                    .frame(width: 12, height: 12)
                                    .scaleEffect(isPlaying ? 1.5 : 1)
                                    .opacity(isPlaying ? 0.6 : 0)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPlaying)
                            )
                        Text("Đang phát trên Samsung Smart TV")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Button {
                        // Disconnect
                    } label: {
                        Text("Ngắt kết nối")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Movie poster + info
                VStack(spacing: 16) {
                    if let url = posterURL {
                        CachedAsyncImage(url: url)
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .white.opacity(0.15), radius: 20, y: -5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    
                    VStack(spacing: 4) {
                        Text(movieTitle)
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if !episodeInfo.isEmpty {
                            Text(episodeInfo)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                // Info overlay (hiển thị khi tap)
                if showInfo {
                    VStack(spacing: 8) {
                        Text("🎬 Đạo diễn: Anthony Russo")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        Text("⭐ IMDb: 8.4")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        Text("🎵 Nhạc phim: Alan Silvestri")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.4)))
                    .opacity(infoOpacity)
                }
                
                Spacer()
                
                // Progress bar
                VStack(spacing: 6) {
                    Slider(value: $currentTime, in: 0...max(duration, 1))
                        .accentColor(.white)
                        .padding(.horizontal, 30)
                    
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text("-" + formatTime(duration - currentTime))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 34)
                }
                
                // Controls
                HStack(spacing: 50) {
                    // Audio select
                    Button {
                        showAudioMenu.toggle()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.system(size: 22))
                            Text(selectedAudio)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Skip back 10s
                    Button {
                        currentTime = max(0, currentTime - 10)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Play/Pause
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                    }
                    
                    // Skip forward 10s
                    Button {
                        currentTime = min(duration, currentTime + 10)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Info toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showInfo.toggle()
                            infoOpacity = showInfo ? 1 : 0
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                            Text("Info")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.top, 10)
                
                // Audio menu
                if showAudioMenu {
                    VStack(spacing: 8) {
                        ForEach(["Vietsub", "Thuyết minh", "Lồng tiếng", "Original"], id: \.self) { audio in
                            Button {
                                selectedAudio = audio
                                showAudioMenu = false
                            } label: {
                                HStack {
                                    Text(audio)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedAudio == audio {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedAudio == audio ? .white.opacity(0.15) : .white.opacity(0.05))
                                )
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.95)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15), lineWidth: 0.5))
                    .padding(.horizontal, 40)
                }
                
                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onTapGesture(count: 2) {
            // Double tap to toggle info
            withAnimation(.easeInOut(duration: 0.3)) {
                showInfo.toggle()
                infoOpacity = showInfo ? 1 : 0
            }
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if isPlaying && currentTime < duration {
                currentTime += 1
            }
        }
    }
    
    func formatTime(_ s: Double) -> String {
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}