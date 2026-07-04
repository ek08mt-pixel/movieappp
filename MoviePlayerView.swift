import SwiftUI
import WebKit

struct MoviePlayerView: View {
    let movieTitle: String
    let movieId: Int
    @Environment(\.dismiss) var dismiss
    @State private var selectedSource = 0
    @State private var isLoading = true
    
    var sources: [(String, String)] {
        [
            ("Vidsrc", "https://vidsrc.to/embed/movie/\(movieId)"),
            ("Vidsrc 2", "https://vidsrc.xyz/embed/movie/\(movieId)"),
            ("2Embed", "https://www.2embed.cc/embed/\(movieId)"),
            ("Vidcloud", "https://vidcloud.icu/embed/movie/\(movieId)"),
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
                    ProgressView().tint(.white)
                }
                
                WebView(urlString: sources[selectedSource].1)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isLoading = false } }
            }
        }
    }
}