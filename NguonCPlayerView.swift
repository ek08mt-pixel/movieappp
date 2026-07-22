import SwiftUI
import WebKit

struct NguonCPlayerView: View {
    let embedURL: URL
    let episodeName: String
    var servers: [(String, URL)] = []
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    @State private var currentURL: URL
    @State private var showServerPicker = false
    @State private var currentServerName = ""
    
    init(embedURL: URL, episodeName: String, servers: [(String, URL)] = []) {
        self.embedURL = embedURL
        self.episodeName = episodeName
        self.servers = servers
        _currentURL = State(initialValue: embedURL)
        _currentServerName = State(initialValue: servers.first?.0 ?? "")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            NguonCWebView(url: currentURL)
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Đang tải \(episodeName)...")
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                }
            }
            
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.4))
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)))
                    }
                    Spacer()
                    Text(episodeName).font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    if !servers.isEmpty {
                        Button { showServerPicker = true } label: {
                            Image(systemName: "list.bullet").font(.system(size: 16)).foregroundColor(.white).padding(8)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 50)
                Spacer()
            }
            
            if showServerPicker {
                Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { showServerPicker = false }
                VStack(spacing: 10) {
                    Text("Chọn server").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    ForEach(servers, id: \.0) { name, url in
                        Button {
                            currentURL = url
                            currentServerName = name
                            showServerPicker = false
                            isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isLoading = false }
                        } label: {
                            Text(name).font(.system(size: 13))
                                .foregroundColor(currentServerName == name ? .black : .white)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(currentServerName == name ? Color.white : Color.white.opacity(0.08)))
                        }
                    }
                }
                .padding(18).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.95)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 0.5))
                .frame(width: 240)
            }
        }
        .statusBarHidden()
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isLoading = false } }
    }
}

struct NguonCWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let pref = WKWebpagePreferences()
        pref.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pref
        
        let script = WKUserScript(source: """
    setTimeout(function() {
        var video = document.querySelector('video');
        if (video) {
            video.setAttribute('playsinline', 'true');
            video.setAttribute('webkit-playsinline', 'true');
            video.controls = false;
            video.style.width = '100%';
            video.style.height = '100%';
            video.play();
        }
        // Ẩn các nút overlay của trang web
        var overlays = document.querySelectorAll('.jw-controls, .jw-icon, .jw-overlay, .jw-button-container, .vjs-control-bar, .plyr__controls, [class*="control"], [class*="button"], [class*="overlay"]');
        for (var i = 0; i < overlays.length; i++) {
            overlays[i].style.display = 'none';
        }
    }, 1500);
    """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.backgroundColor = .black
        wv.isOpaque = false
        wv.scrollView.bounces = false
        wv.navigationDelegate = context.coordinator
        wv.load(URLRequest(url: url))
        return wv
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.targetFrame == nil { decisionHandler(.cancel); return }
            decisionHandler(.allow)
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("""
                var video = document.querySelector('video');
                if (video) { video.play(); }
            """)
        }
    }
}