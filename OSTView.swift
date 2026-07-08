import SwiftUI
import AVKit

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
    @StateObject private var ostManager = OSTManager.shared
    @State private var currentTrack: OSTTrack?
    @State private var isPlaying = false
    @Environment(\.dismiss) var dismiss
    
    let baseMusicURL = "https://raw.githubusercontent.com/ek08mt-pixel/movieappp/main"
    
    var tracks: [OSTTrack] {
        [
            OSTTrack(title: "Cornfield Chase", movie: "Interstellar", composer: "Hans Zimmer", posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", mp3URL: "\(baseMusicURL)/music/Interstellar%20Official%20Soundtrack%20%20Cornfield%20Chase%20%20Hans%20Zimmer%20%20WaterTower.mp3"),
            OSTTrack(title: "S.T.A.Y.", movie: "Interstellar", composer: "Hans Zimmer", posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", mp3URL: "\(baseMusicURL)/music/Hans%20Zimmer%20-%20S%20T%20A%20Y%20(Interstellar).mp3"),
            OSTTrack(title: "Young and Beautiful", movie: "The Great Gatsby", composer: "Lana Del Rey", posterPath: "/oFJXce9i3r3RQujXwjFqGQH3MJq.jpg", mp3URL: "\(baseMusicURL)/music/Lana%20Del%20Rey%20-%20Young%20and%20Beautiful%20(from%20The%20Great%20Gatsby%20Soundtrack).mp3"),
            OSTTrack(title: "Stranger Things Theme", movie: "Stranger Things", composer: "Kyle Dixon & Michael Stein", posterPath: "/56v2KjBlU4XaOv9rVYEQypROD7P.jpg", mp3URL: "\(baseMusicURL)/music/Stranger%20Things%20-%20%20Kyle%20Dixon%20&%20%20Michael%20Stein.mp3"),
            OSTTrack(title: "Running Up That Hill", movie: "Stranger Things", composer: "Kate Bush", posterPath: "/56v2KjBlU4XaOv9rVYEQypROD7P.jpg", mp3URL: "\(baseMusicURL)/music/Kate%20Bush%20-%20Running%20Up%20That%20Hill%20(HQ%20Audio%20Remastered)%20Stranger%20Things%20S4.mp3"),
            OSTTrack(title: "Main Theme", movie: "Game of Thrones", composer: "Ramin Djawadi", posterPath: "/7WUHnWGx5OO145IRpPD7Q3jPqcX.jpg", mp3URL: "\(baseMusicURL)/music/Game%20of%20Thrones%20-%20Main%20Theme%20(Extended)%20HD.mp3"),
            OSTTrack(title: "Main Title Theme", movie: "Succession", composer: "Nicholas Britell", posterPath: "/dKq9jQ3M7G5H7gX0vL5qF0Y4c3X.jpg", mp3URL: "\(baseMusicURL)/music/Succession%20(Main%20Title%20Theme)%20-%20Nicholas%20Britell%20%20Succession%20(HBO%20Original%20Series%20Soundtrack).mp3"),
            OSTTrack(title: "Red Right Hand", movie: "Peaky Blinders", composer: "Flood Remix", posterPath: "/r7N2Vz8xO0lXkDQ9iLcVbGX4f3X.jpg", mp3URL: "\(baseMusicURL)/music/Red%20Right%20Hand%20(Peaky%20Blinders%20Theme)%20(Flood%20Remix).mp3"),
            OSTTrack(title: "Light of the Seven", movie: "Game of Thrones", composer: "Ramin Djawadi", posterPath: "/7WUHnWGx5OO145IRpPD7Q3jPqcX.jpg", mp3URL: "\(baseMusicURL)/music/Light%20of%20the%20Seven%20%20Game%20of%20Thrones%20(Music%20from%20the%20HBO%20Series%20-%20Season%206).mp3"),
            OSTTrack(title: "All For Us", movie: "Euphoria", composer: "Labrinth & Zendaya", posterPath: "/vGQH4jXZ9xL0lK5fQ7wJc3bN8mX.jpg", mp3URL: "\(baseMusicURL)/music/Labrinth,%20Zendaya%20-%20All%20For%20Us%20%20euphoria%20OST.mp3"),
            OSTTrack(title: "Still Don't Know My Name", movie: "Euphoria", composer: "Labrinth", posterPath: "/vGQH4jXZ9xL0lK5fQ7wJc3bN8mX.jpg", mp3URL: "\(baseMusicURL)/music/Labrinth%20-%20Still%20Dont%20Know%20My%20Name%20(Official%20Video)%20%20euphoria%20(Original%20HBO%20Score).mp3"),
        ]
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.white).padding(10)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                    }
                    Spacer()
                    Text("OST").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Spacer(); Spacer().frame(width: 44)
                }.padding(.horizontal, 20).padding(.top, 50)
                
                if let track = currentTrack {
                    VStack(spacing: 16) {
                        if let posterURL = track.posterURL {
                            CachedAsyncImage(url: posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 180, height: 270)
                                .clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: .white.opacity(0.1), radius: 20)
                        }
                        Text(track.title).font(.system(size: 20, weight: .bold, design: .serif)).foregroundColor(.white)
                        Text(track.movie).font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                        Text(track.composer).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                        HStack(spacing: 40) {
                            Button {
                                if let idx = tracks.firstIndex(of: track), idx > 0 { playTrack(tracks[idx - 1]) }
                            } label: { Image(systemName: "backward.fill").font(.system(size: 22)).foregroundColor(.white) }
                            Button { togglePlayback() } label: {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 56)).foregroundColor(.white)
                            }
                            Button {
                                if let idx = tracks.firstIndex(of: track), idx < tracks.count - 1 { playTrack(tracks[idx + 1]) }
                            } label: { Image(systemName: "forward.fill").font(.system(size: 22)).foregroundColor(.white) }
                        }
                    }
                } else {
                    Text("Chọn một bản OST để nghe").font(.system(size: 16)).foregroundColor(.white.opacity(0.5)).padding(.top, 40)
                }
                
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(tracks) { track in
                            Button {
                                if currentTrack?.id == track.id { togglePlayback() } else { playTrack(track) }
                            } label: {
                                HStack(spacing: 12) {
                                    if let posterURL = track.posterURL {
                                        CachedAsyncImage(url: posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 44, height: 66).clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(track.title).font(.system(size: 14, weight: .medium)).foregroundColor(currentTrack?.id == track.id ? .yellow : .white)
                                        Text("\(track.movie) • \(track.composer)").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
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
        .onAppear {
            ostManager.togglePlayback = { togglePlayback() }
            ostManager.stopPlayback = {
                ostManager.audioPlayer?.pause(); isPlaying = false; currentTrack = nil
                ostManager.isPlaying = false; ostManager.currentTrack = ""; ostManager.currentMovie = ""
                ostManager.currentPoster = nil; ostManager.audioPlayer = nil
            }
        }
        .onDisappear {
            if isPlaying, let track = currentTrack {
                ostManager.currentTrack = track.title; ostManager.currentMovie = track.movie
                ostManager.currentPoster = track.posterPath; ostManager.isPlaying = true
                ostManager.audioPlayer = ostManager.audioPlayer ?? AVPlayer()
            }
        }
    }
    
    func playTrack(_ track: OSTTrack) {
        currentTrack = track
        guard let url = track.streamURL else { return }
        ostManager.audioPlayer?.pause()
        ostManager.audioPlayer = AVPlayer(url: url)
        ostManager.audioPlayer?.play()
        isPlaying = true
        ostManager.isPlaying = true
    }
    
    func togglePlayback() {
        if isPlaying {
            ostManager.audioPlayer?.pause()
            isPlaying = false
        } else {
            ostManager.audioPlayer?.play()
            isPlaying = true
        }
    }
}