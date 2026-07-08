import SwiftUI
import AVKit

// Không cần OSTManager nữa, dùng AVPlayer trực tiếp

struct OSTTrack: Identifiable, Hashable {
    let id = UUID()
    let title: String; let movie: String; let composer: String
    let posterPath: String; let mp3URL: String
    var posterURL: URL? { URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") }
    var streamURL: URL? { URL(string: mp3URL) }
    func hash(into hasher: inout Hasher) { hasher.combine(mp3URL) }
    static func == (lhs: OSTTrack, rhs: OSTTrack) -> Bool { lhs.mp3URL == rhs.mp3URL }
}

struct OSTView: View {
    @State private var audioPlayer: AVPlayer?
    @State private var currentTrack: OSTTrack?
    @State private var isPlaying = false
    @Environment(\.dismiss) var dismiss
    
    let tracks: [OSTTrack] = [
        OSTTrack(
            title: "Running Up That Hill",
            movie: "Stranger Things",
            composer: "Kate Bush",
            posterPath: "/56v2KjBlU4XaOv9rVYEQypROD7P.jpg",
            mp3URL: "https://raw.githubusercontent.com/ek08mt-pixel/movieappp/main/music/Kate%20Bush%20-%20Running%20Up%20That%20Hill%20(HQ%20Audio%20Remastered)%20Stranger%20Things%20S4.mp3"
        ),
        // Thêm bài mới vào đây sau
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.white).padding(10)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                    }
                    Spacer()
                    Text("OST").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Spacer(); Spacer().frame(width: 44)
                }.padding(.horizontal, 20).padding(.top, 50)
                
                // Now Playing
                if let track = currentTrack {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 10)
                        if let posterURL = track.posterURL {
                            CachedAsyncImage(url: posterURL)
                                .aspectRatio(2/3, contentMode: .fill).frame(width: 180, height: 270)
                                .clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: .white.opacity(0.1), radius: 20)
                        }
                        Text(track.title).font(.system(size: 20, weight: .bold, design: .serif)).foregroundColor(.white)
                        Text(track.movie).font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                        Text(track.composer).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                        
                        HStack(spacing: 40) {
                            Button {
                                if let idx = tracks.firstIndex(of: track), idx > 0 {
                                    playTrack(tracks[idx - 1])
                                }
                            } label: { Image(systemName: "backward.fill").font(.system(size: 22)).foregroundColor(.white) }
                            
                            Button { togglePlayback() } label: {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 56)).foregroundColor(.white)
                            }
                            
                            Button {
                                if let idx = tracks.firstIndex(of: track), idx < tracks.count - 1 {
                                    playTrack(tracks[idx + 1])
                                }
                            } label: { Image(systemName: "forward.fill").font(.system(size: 22)).foregroundColor(.white) }
                        }
                        Spacer().frame(height: 10)
                    }
                } else {
                    Text("Chọn một bản OST để nghe").font(.system(size: 16)).foregroundColor(.white.opacity(0.5)).padding(.top, 40)
                }
                
                // Track List
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(tracks) { track in
                            Button {
                                if currentTrack?.id == track.id { togglePlayback() }
                                else { playTrack(track) }
                            } label: {
                                HStack(spacing: 12) {
                                    if let posterURL = track.posterURL {
                                        CachedAsyncImage(url: posterURL).aspectRatio(2/3, contentMode: .fill)
                                            .frame(width: 44, height: 66).clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(track.title).font(.system(size: 14, weight: .medium))
                                            .foregroundColor(currentTrack?.id == track.id ? .yellow : .white)
                                        Text("\(track.movie) • \(track.composer)").font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.5)).lineLimit(1)
                                    }
                                    Spacer()
                                    if currentTrack?.id == track.id && isPlaying {
                                        Image(systemName: "waveform").font(.system(size: 12)).foregroundColor(.yellow)
                                    }
                                }.padding(.horizontal, 20).padding(.vertical, 6)
                            }
                        }
                    }.padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            audioPlayer?.pause()
        }
    }
    
    func playTrack(_ track: OSTTrack) {
        currentTrack = track
        guard let url = track.streamURL else { return }
        audioPlayer?.pause()
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
        isPlaying = true
    }
    
    func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            audioPlayer?.play()
            isPlaying = true
        }
    }
}