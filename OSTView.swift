import SwiftUI
import WebKit

class OSTManager: ObservableObject {
    static let shared = OSTManager()
    @Published var isPlaying = false
    @Published var currentTrack: String = ""
    @Published var currentMovie: String = ""
    @Published var currentPoster: String? = nil
    @Published var currentYoutubeID: String? = nil
    var togglePlayback: (() -> Void)?
    var stopPlayback: (() -> Void)?
}

struct OSTTrack: Identifiable, Hashable {
    let id = UUID()
    let title: String; let movie: String; let composer: String
    let tmdbMovieID: Int; let posterPath: String; let youtubeID: String
    var posterURL: URL? { URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") }
    func hash(into hasher: inout Hasher) { hasher.combine(youtubeID) }
    static func == (lhs: OSTTrack, rhs: OSTTrack) -> Bool { lhs.youtubeID == rhs.youtubeID }
}

struct OSTLibrary {
    static let all: [OSTTrack] = [
        OSTTrack(title: "Time", movie: "Inception", composer: "Hans Zimmer", tmdbMovieID: 27205, posterPath: "/s3TBrRGB1iav7gFOCNx3H31MoES.jpg", youtubeID: "RxabLA7UQ9k"),
        OSTTrack(title: "Running Up That Hill", movie: "Stranger Things", composer: "Kate Bush", tmdbMovieID: 66732, posterPath: "/56v2KjBlU4XaOv9rVYEQypROD7P.jpg", youtubeID: "wp43OdtAAkM"),
        OSTTrack(title: "He's a Pirate", movie: "Pirates of the Caribbean", composer: "Klaus Badelt", tmdbMovieID: 22, posterPath: "/zQp4HhJj2DVmJdBxJQ6v8gHx7Vx.jpg", youtubeID: "27mB8verLK8"),
        OSTTrack(title: "Cornfield Chase", movie: "Interstellar", composer: "Hans Zimmer", tmdbMovieID: 157336, posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", youtubeID: "NxsN1JjL6J8"),
        OSTTrack(title: "Now We Are Free", movie: "Gladiator", composer: "Hans Zimmer", tmdbMovieID: 98, posterPath: "/5EufsDwXdY2CVttYOk2WtYhgKpa.jpg", youtubeID: "kSIeCIC6Ih0"),
        OSTTrack(title: "Hedwig's Theme", movie: "Harry Potter", composer: "John Williams", tmdbMovieID: 671, posterPath: "/wuMc08IPKEatf9rnMNXvIDxqP4W.jpg", youtubeID: "wtHra9tFISY"),
        OSTTrack(title: "Jurassic Park Theme", movie: "Jurassic Park", composer: "John Williams", tmdbMovieID: 329, posterPath: "/oU7Oq2kFAAlGqbHh5rP3A2KaKj2.jpg", youtubeID: "D8zlUUrFK-M"),
        OSTTrack(title: "Star Wars Main Theme", movie: "Star Wars", composer: "John Williams", tmdbMovieID: 11, posterPath: "/6FfCtAuVAW8XJjZ7eWeLibRLWTw.jpg", youtubeID: "_D0ZQPqeJkk"),
        OSTTrack(title: "Duel of the Fates", movie: "Star Wars: Phantom Menace", composer: "John Williams", tmdbMovieID: 1893, posterPath: "/6wkfovpn7Eq8dYNKaG5PY3q2oq6.jpg", youtubeID: "qzVBqBosf5w"),
        OSTTrack(title: "The Imperial March", movie: "Star Wars", composer: "John Williams", tmdbMovieID: 1891, posterPath: "/2l05cFW0jVXTjJyY6kRkNnrNrL.jpg", youtubeID: "7x2wJxSK4sY"),
        OSTTrack(title: "My Heart Will Go On", movie: "Titanic", composer: "James Horner", tmdbMovieID: 597, posterPath: "/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg", youtubeID: "3gK_2XdjOdY"),
        OSTTrack(title: "The Avengers Theme", movie: "The Avengers", composer: "Alan Silvestri", tmdbMovieID: 24428, posterPath: "/RYMX2wcKCBAr24UyPD7xwmjaTn.jpg", youtubeID: "cVq4zJ1WbaQ"),
        OSTTrack(title: "Game of Thrones Theme", movie: "Game of Thrones", composer: "Ramin Djawadi", tmdbMovieID: 1399, posterPath: "/7WUHnWGx5OO145IRpPD7Q3jPqcX.jpg", youtubeID: "s7L2PVdrb_8"),
        OSTTrack(title: "Concerning Hobbits", movie: "Lord of the Rings", composer: "Howard Shore", tmdbMovieID: 120, posterPath: "/6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg", youtubeID: "aWAsdqQNs0I"),
        OSTTrack(title: "One Summer's Day", movie: "Spirited Away", composer: "Joe Hisaishi", tmdbMovieID: 129, posterPath: "/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg", youtubeID: "TK1Ij_-mank"),
        OSTTrack(title: "Merry Go Round of Life", movie: "Howl's Moving Castle", composer: "Joe Hisaishi", tmdbMovieID: 4935, posterPath: "/7Dl4WMkLRAnZQxWFq8QMUJSUNIG.jpg", youtubeID: "f7SS57LCPUo"),
        OSTTrack(title: "Skyfall", movie: "Skyfall", composer: "Adele", tmdbMovieID: 37724, posterPath: "/6VkZqixFuEqp8UqFS9IuZqWnJjM.jpg", youtubeID: "DeumyOzKqgI"),
        OSTTrack(title: "Shallow", movie: "A Star is Born", composer: "Lady Gaga", tmdbMovieID: 332562, posterPath: "/wrFpXMNBRj2PBiN4Z5kix51XaIZ.jpg", youtubeID: "bo_efYhYU2A"),
        OSTTrack(title: "Let It Go", movie: "Frozen", composer: "Idina Menzel", tmdbMovieID: 109445, posterPath: "/kgwjIb2JDHRhNk13lmSxiClFjVk.jpg", youtubeID: "L0MK7qz13bU"),
        OSTTrack(title: "Happy", movie: "Despicable Me 2", composer: "Pharrell Williams", tmdbMovieID: 93456, posterPath: "/kQrY7oLG2fVn9FmXFNxGY3NzNx.jpg", youtubeID: "ZbZSe6N_BXs"),
        OSTTrack(title: "Eye of the Tiger", movie: "Rocky III", composer: "Survivor", tmdbMovieID: 1371, posterPath: "/fNOH9f1aA7XRTzl1sAOx9iF553Q.jpg", youtubeID: "btPJPFnesV4"),
        OSTTrack(title: "Lose Yourself", movie: "8 Mile", composer: "Eminem", tmdbMovieID: 65, posterPath: "/8VZ6xQ5gHkQvFCqXqQ9QJ8QfS0C.jpg", youtubeID: "XbGs_qK2PQA"),
        OSTTrack(title: "Bohemian Rhapsody", movie: "Bohemian Rhapsody", composer: "Queen", tmdbMovieID: 424694, posterPath: "/lHu1wtNaczFPGFDTrjCSzeLPTKN.jpg", youtubeID: "fJ9rUzIMcZQ"),
        OSTTrack(title: "Zenzenzense", movie: "Your Name", composer: "Radwimps", tmdbMovieID: 372058, posterPath: "/q719jXXEzOZfHZTeBgPkNXoYdNI.jpg", youtubeID: "PDSkFeMVNFs"),
        OSTTrack(title: "Dune Main Theme", movie: "Dune", composer: "Hans Zimmer", tmdbMovieID: 438631, posterPath: "/d5NXSklXo0qyIYkgV94XAgMIckC.jpg", youtubeID: "wQjxB6gVnQM"),
        OSTTrack(title: "Can You Hear The Music", movie: "Oppenheimer", composer: "Ludwig Göransson", tmdbMovieID: 872585, posterPath: "/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", youtubeID: "4JvQ1h2UYr8"),
        OSTTrack(title: "Barbie World", movie: "Barbie", composer: "Mark Ronson", tmdbMovieID: 346698, posterPath: "/iuFNMS8U5cJuJ3gHkjgJ0A9UyUE.jpg", youtubeID: "CUj2AWEfdwY"),
        OSTTrack(title: "Peaches", movie: "Super Mario Bros", composer: "Jack Black", tmdbMovieID: 502356, posterPath: "/qNBAXBIQlnOThrVvA6mA2B5ggV6.jpg", youtubeID: "aG7Cd3tJK8I"),
        OSTTrack(title: "Sunflower", movie: "Spider-Man: Into Spider-Verse", composer: "Post Malone", tmdbMovieID: 324857, posterPath: "/iiZZdoQBEYBv6id8su7ImL0oCbD.jpg", youtubeID: "ApXoWvfEYVU"),
        OSTTrack(title: "Mission: Impossible Theme", movie: "Mission: Impossible", composer: "Lalo Schifrin", tmdbMovieID: 954, posterPath: "/iYq3d5XfJ7V2rQbG0qFhGXnAyEi.jpg", youtubeID: "XAYhNHhxN0A"),
        OSTTrack(title: "James Bond Theme", movie: "James Bond", composer: "Monty Norman", tmdbMovieID: 658, posterPath: "/dNVrMjHlNarJDZoJ0LVgrIVwTFT.jpg", youtubeID: "U9FzgsF2T-s"),
        OSTTrack(title: "Back to the Future Theme", movie: "Back to the Future", composer: "Alan Silvestri", tmdbMovieID: 105, posterPath: "/fNOH9f1aA7XRTzl1sAOx9iF553Q.jpg", youtubeID: "gJOkO4WQRiA"),
        OSTTrack(title: "Forrest Gump Theme", movie: "Forrest Gump", composer: "Alan Silvestri", tmdbMovieID: 13, posterPath: "/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg", youtubeID: "x7h4FMIVRR0"),
        OSTTrack(title: "Danger Zone", movie: "Top Gun", composer: "Kenny Loggins", tmdbMovieID: 744, posterPath: "/x5Gh0d8rZkmQvQjR6mzHh4QxQyY.jpg", youtubeID: "siwpn14IE7E"),
        OSTTrack(title: "Take My Breath Away", movie: "Top Gun", composer: "Berlin", tmdbMovieID: 744, posterPath: "/x5Gh0d8rZkmQvQjR6mzHh4QxQyY.jpg", youtubeID: "Bx51e1v1fKM"),
    ]
}

struct OSTView: View {
    @StateObject private var ostManager = OSTManager.shared
    @State private var currentTrack: OSTTrack?
    @State private var isPlaying = false
    @State private var youtubePlayer: YouTubeAudioPlayer?
    @State private var dailyTracks: [OSTTrack] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            YouTubeAudioPlayerView(player: $youtubePlayer).frame(width: 0, height: 0).opacity(0)
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                    }
                    Spacer()
                    Text("OST").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Spacer(); Spacer().frame(width: 44)
                }.padding(.horizontal, 20).padding(.top, 50)
                
                if let track = currentTrack {
                    VStack(spacing: 16) {
                        if let posterURL = track.posterURL {
                            CachedAsyncImage(url: posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 180, height: 270).clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: .white.opacity(0.1), radius: 20)
                        }
                        Text(track.title).font(.system(size: 20, weight: .bold, design: .serif)).foregroundColor(.white)
                        Text(track.movie).font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                        Text(track.composer).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                        HStack(spacing: 40) {
                            Button {
                                if let idx = dailyTracks.firstIndex(of: track), idx > 0 { currentTrack = dailyTracks[idx - 1]; playTrack(dailyTracks[idx - 1]) }
                            } label: { Image(systemName: "backward.fill").font(.system(size: 22)).foregroundColor(.white) }
                            Button { togglePlayback() } label: {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 56)).foregroundColor(.white)
                            }
                            Button {
                                if let idx = dailyTracks.firstIndex(of: track), idx < dailyTracks.count - 1 { currentTrack = dailyTracks[idx + 1]; playTrack(dailyTracks[idx + 1]) }
                            } label: { Image(systemName: "forward.fill").font(.system(size: 22)).foregroundColor(.white) }
                        }
                    }
                } else {
                    Text("Chọn một bản OST để nghe").font(.system(size: 16)).foregroundColor(.white.opacity(0.5)).padding(.top, 40)
                }
                
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(dailyTracks) { track in
                            Button {
                                if currentTrack == track { togglePlayback() } else { currentTrack = track; playTrack(track) }
                            } label: {
                                HStack(spacing: 12) {
                                    if let posterURL = track.posterURL {
                                        CachedAsyncImage(url: posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 44, height: 66).clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(track.title).font(.system(size: 14, weight: .medium)).foregroundColor(currentTrack == track ? .yellow : .white)
                                        Text("\(track.movie) • \(track.composer)").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                                    }
                                    Spacer()
                                    if currentTrack == track && isPlaying { Image(systemName: "waveform").font(.system(size: 12)).foregroundColor(.yellow) }
                                }.padding(.horizontal, 20).padding(.vertical, 6)
                            }
                        }
                    }.padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .task { dailyTracks = OSTLibrary.all.shuffled().prefix(20).map { $0 } }
        .onAppear {
            ostManager.togglePlayback = { togglePlayback() }
            ostManager.stopPlayback = {
                youtubePlayer?.pause(); isPlaying = false; currentTrack = nil
                ostManager.isPlaying = false; ostManager.currentTrack = ""; ostManager.currentMovie = ""
                ostManager.currentPoster = nil; ostManager.currentYoutubeID = nil
            }
        }
        .onDisappear {
            if isPlaying, let track = currentTrack {
                ostManager.currentTrack = track.title; ostManager.currentMovie = track.movie
                ostManager.currentPoster = track.posterPath; ostManager.currentYoutubeID = track.youtubeID
                ostManager.isPlaying = true
            }
        }
    }
    
    func playTrack(_ track: OSTTrack) {
        youtubePlayer?.loadYouTube(videoID: track.youtubeID)
        isPlaying = true
        ostManager.currentTrack = track.title; ostManager.currentMovie = track.movie
        ostManager.currentPoster = track.posterPath; ostManager.currentYoutubeID = track.youtubeID
    }
    
    func togglePlayback() {
        if isPlaying { youtubePlayer?.pause(); isPlaying = false } else { youtubePlayer?.play(); isPlaying = true }
    }
}

class YouTubeAudioPlayer: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    override init() {
        super.init()
        let config = WKWebViewConfiguration(); config.allowsInlineMediaPlayback = true; config.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: config); webView?.navigationDelegate = self; webView?.isHidden = true
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let rootVC = windowScene.windows.first?.rootViewController { rootVC.view.addSubview(webView!) }
    }
    func loadYouTube(videoID: String) {
        webView?.loadHTMLString("<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,initial-scale=1.0'></head><body style='margin:0;background:black;'><div id='player'></div><script src='https://www.youtube.com/iframe_api'></script><script>var player;function onYouTubeIframeAPIReady(){player=new YT.Player('player',{videoId:'\(videoID)',width:'100%',height:'100%',playerVars:{autoplay:1,controls:0,modestbranding:1,playsinline:1},events:{onReady:function(e){e.target.playVideo()}}})}</script></body></html>", baseURL: URL(string: "https://www.youtube.com"))
    }
    func play() { webView?.evaluateJavaScript("player?.playVideo()") }
    func pause() { webView?.evaluateJavaScript("player?.pauseVideo()") }
}

struct YouTubeAudioPlayerView: UIViewRepresentable {
    @Binding var player: YouTubeAudioPlayer?
    func makeUIView(context: Context) -> UIView { UIView(frame: .zero) }
    func updateUIView(_ uiView: UIView, context: Context) {}
}