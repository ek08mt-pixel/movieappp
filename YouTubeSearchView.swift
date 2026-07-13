import SwiftUI
import WebKit

struct YouTubeVideo: Identifiable, Codable {
    let id: String { videoID }
    let videoID: String
    let title: String
    let thumbnailURL: String
    let channelTitle: String
}

struct YouTubeSearchView: View {
    @Environment(\.dismiss) var dismiss
    @State private var query = ""
    @State private var results: [YouTubeVideo] = []
    @State private var isLoading = false
    @State private var selectedVideo: YouTubeVideo?
    @State private var showPlayer = false
    
    let apiKey = "AIzaSyC2V7qNDrVdX6x1CgFdVpJ0CnMp7S8tHZw"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Tìm kiếm YouTube...", text: $query)
                            .foregroundColor(.white)
                            .onSubmit { search() }
                        if !query.isEmpty {
                            Button { query = ""; results = [] } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                    .padding()
                    
                    if isLoading {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(results) { video in
                                    Button {
                                        selectedVideo = video
                                        showPlayer = true
                                    } label: {
                                        HStack(spacing: 12) {
                                            AsyncImage(url: URL(string: video.thumbnailURL)) { img in
                                                img.resizable().aspectRatio(16/9, contentMode: .fill)
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial)
                                            }
                                            .frame(width: 120, height: 68)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(video.title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(2)
                                                Text(video.channelTitle).font(.system(size: 11)).foregroundColor(.gray)
                                            }
                                            Spacer()
                                        }
                                        .padding(10).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.3)))
                                    }
                                }
                            }.padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
            .fullScreenCover(isPresented: $showPlayer) {
                if let video = selectedVideo {
                    YouTubePlayerView(videoID: video.videoID, videoTitle: video.title)
                }
            }
        }
    }
    
    func search() {
        guard !query.isEmpty else { return }
        isLoading = true
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=20&q=\(encoded)&key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            let videos = items.compactMap { item -> YouTubeVideo? in
                guard let id = item["id"] as? [String: Any],
                      let videoID = id["videoId"] as? String,
                      let snippet = item["snippet"] as? [String: Any],
                      let title = snippet["title"] as? String,
                      let channelTitle = snippet["channelTitle"] as? String,
                      let thumbnails = snippet["thumbnails"] as? [String: Any],
                      let defaultThumb = thumbnails["medium"] as? [String: Any],
                      let thumbnailURL = defaultThumb["url"] as? String else { return nil }
                return YouTubeVideo(videoID: videoID, title: title, thumbnailURL: thumbnailURL, channelTitle: channelTitle)
            }
            DispatchQueue.main.async {
                results = videos
                isLoading = false
            }
        }.resume()
    }
}

struct YouTubePlayerView: View {
    let videoID: String
    let videoTitle: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                    }
                    Spacer()
                    Text(videoTitle).font(.system(size: 14, weight: .medium)).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Color.clear.frame(width: 36)
                }.padding(.horizontal).padding(.top, 50)
                
                YouTubeWebView(videoID: videoID)
            }
        }
    }
}

struct YouTubeWebView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.backgroundColor = .black
        wv.isOpaque = false
        if let url = URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=1") {
            wv.load(URLRequest(url: url))
        }
        return wv
    }
    
    func updateUIViewController(_ uiView: WKWebView, context: Context) {}
}