import SwiftUI
import WebKit

struct MoviePlayerView: View {
    let movieTitle: String
    let movieId: Int
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var selectedSource = 0
    
    var sources: [(String, String)] {
        [
            ("Source 1", "https://multiembed.mov/directstream.php?video_id=\(movieId)&tmdb=1"),
            ("Source 2", "https://www.2embed.cc/embed/\(movieId)"),
            ("Source 3", "https://autoembed.to/movie/tmdb/\(movieId)"),
        ]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.white)
                    }
                    Spacer()
                    Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Menu {
                        ForEach(0..<sources.count, id: \.self) { i in
                            Button(sources[i].0) { selectedSource = i; isLoading = true }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill").font(.system(size: 24)).foregroundColor(.white)
                    }
                }.padding()
                
                if isLoading {
                    ProgressView().tint(.white).padding(.top, 100)
                }
                
                WebView(urlString: sources[selectedSource].1)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isLoading = false } }
            }
        }
    }
}