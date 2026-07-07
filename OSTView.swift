import SwiftUI
import AVKit

// MARK: - OST Model
struct OSTTrack: Identifiable {
    let id = UUID()
    let title: String
    let movie: String
    let composer: String
    let posterURL: URL?
    let previewURL: URL
}

// MARK: - OST View
struct OSTView: View {
    @StateObject private var ostManager = OSTManager.shared
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTrack: OSTTrack?
    @Environment(\.dismiss) var dismiss
    
    // OST mẫu từ các phim nổi tiếng
    let tracks: [OSTTrack] = [
        OSTTrack(title: "Time", movie: "Inception", composer: "Hans Zimmer",
                 posterURL: URL(string: "https://image.tmdb.org/t/p/w500/s3TBrRGB1iav7gFOCNx3H31MoES.jpg"),
                 previewURL: URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Kevin_MacLeod/Best_of_2014/Kevin_MacLeod_-_Inception_Theme.mp3")!),
        OSTTrack(title: "He's a Pirate", movie: "Pirates of the Caribbean", composer: "Klaus Badelt",
                 posterURL: URL(string: "https://image.tmdb.org/t/p/w500/zQp4HhJj2DVmJdBxJQ6v8gHx7Vx.jpg"),
                 previewURL: URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Kevin_MacLeod/Agnus_Dei_X/Kevin_MacLeod_-_He_s_a_Pirate.mp3")!),
        OSTTrack(title: "Now We Are Free", movie: "Gladiator", composer: "Hans Zimmer",
                 posterURL: URL(string: "https://image.tmdb.org/t/p/w500/5EufsDwXdY2CVttYOk2WtYhgKpa.jpg"),
                 previewURL: URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Kevin_MacLeod/Best_of_2014/Kevin_MacLeod_-_Gladiator_Theme.mp3")!),
        OSTTrack(title: "Interstellar Main Theme", movie: "Interstellar", composer: "Hans Zimmer",
                 posterURL: URL(string: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
                 previewURL: URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Kevin_MacLeod/Best_of_2014/Kevin_MacLeod_-_Interstellar.mp3")!),
        OSTTrack(title: "The Dark Knight Theme", movie: "The Dark Knight", composer: "Hans Zimmer",
                 posterURL: URL(string: "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911B6EMThhKzGYV.jpg"),
                 previewURL: URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Kevin_MacLeod/Best_of_2014/Kevin_MacLeod_-_Batman_Theme.mp3")!),
        OSTTrack(title: "Jurassic Park Theme", movie: "Jurassic Park", composer: "John Williams",
                 posterURL: URL(string: "https://image.tmdb.org/t/p/w500/oU7Oq2kFAAlGqbHh5rP3A2KaKj2.jpg"),
                 previewURL: URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Kevin_MacLeod/Best_of_2014/Kevin_MacLeod_-_Jurassic_Park_Theme.mp3")!),
        OSTTrack(title: "Star Wars Main Theme", movie: "Star Wars", composer: "John Williams",
                 posterURL: URL(string: "https://image.tmdb.org/t/p/w500/6FfCtAuVAW8XJjZ7eWeLibRLWTw.jpg"),
                 previewURL: URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Kevin_MacLeod/Best_of_2014/Kevin_MacLeod_-_Star_Wars_Theme.mp3")!),
        OSTTrack(title: "Harry Potter Theme", movie: "Harry Potter", composer: "John Williams",
                 posterURL: URL(string: "https://image.tmdb.org/t/p/w500/wuMc08IPKEatf9rnMNXvIDxqP4W.jpg"),
                 previewURL: URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Kevin_MacLeod/Best_of_2014/Kevin_MacLeod_-_Harry_Potter_Theme.mp3")!),
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                    }
                    Spacer()
                    Text("OST").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                // Now Playing
                if let track = currentTrack {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 20)
                        
                        if let posterURL = track.posterURL {
                            CachedAsyncImage(url: posterURL)
                                .aspectRatio(2/3, contentMode: .fill)
                                .frame(width: 200, height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .white.opacity(0.1), radius: 20)
                        }
                        
                        VStack(spacing: 6) {
                            Text(track.title)
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            Text(track.movie)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            Text(track.composer)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        // Playback controls
                        HStack(spacing: 40) {
                            Button {
                                // Previous
                            } label: {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            
                            Button {
                                togglePlayback(track)
                            } label: {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            }
                            
                            Button {
                                // Next
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer().frame(height: 30)
                    }
                } else {
                    Spacer().frame(height: 30)
                    Text("Chọn một bản OST để nghe")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer().frame(height: 30)
                }
                
                // Track List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tracks) { track in
                            Button {
                                currentTrack = track
                                playTrack(track)
                            } label: {
                                HStack(spacing: 12) {
                                    if let posterURL = track.posterURL {
                                        CachedAsyncImage(url: posterURL)
                                            .aspectRatio(2/3, contentMode: .fill)
                                            .frame(width: 50, height: 75)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial.opacity(0.3))
                                            .frame(width: 50, height: 75)
                                            .overlay(Image(systemName: "music.note").foregroundColor(.white.opacity(0.5)))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(currentTrack?.id == track.id ? .yellow : .white)
                                        Text(track.movie)
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    if currentTrack?.id == track.id && isPlaying {
                                        Image(systemName: "waveform")
                                            .font(.system(size: 14))
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            // Khi rời màn hình, nếu đang phát thì hiện Dynamic Island
            if isPlaying, let track = currentTrack {
                ostManager.currentTrack = track.title
                ostManager.currentMovie = track.movie
                ostManager.isPlaying = true
            }
        }
    }
    
    func playTrack(_ track: OSTTrack) {
        audioPlayer?.pause()
        audioPlayer = AVPlayer(url: track.previewURL)
        audioPlayer?.play()
        isPlaying = true
    }
    
    func togglePlayback(_ track: OSTTrack) {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            if audioPlayer == nil {
                audioPlayer = AVPlayer(url: track.previewURL)
            }
            audioPlayer?.play()
            isPlaying = true
        }
    }
}