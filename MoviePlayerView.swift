import SwiftUI
import WebKit

struct MoviePlayerView: View {
    let movieTitle: String
    let movieId: Int
    @Environment(\.dismiss) var dismiss
    @State private var selectedSource = 0
    let sources = ["Vidsrc", "Vidsrc 2"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.white) }
                    Spacer()
                    Text(movieTitle).font(.headline).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Menu {
                        ForEach(0..<sources.count, id: \.self) { i in Button(sources[i]) { selectedSource = i } }
                    } label: { Image(systemName: "ellipsis.circle.fill").font(.system(size: 24)).foregroundColor(.white) }
                }.padding()
                if selectedSource == 0 { WebView(urlString: "https://vidsrc.to/embed/movie/\(movieId)") }
                else { WebView(urlString: "https://vidsrc.xyz/embed/movie/\(movieId)") }
            }
        }
    }
}