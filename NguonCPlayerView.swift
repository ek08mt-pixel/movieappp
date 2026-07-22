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
    @State private var isLandscape = false
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var isPlaying = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    
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
            
            NguonCWebView(url: currentURL, isPlaying: $isPlaying, currentTime: $currentTime, duration: $duration)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                    resetControlsTimer()
                }
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Đang tải \(episodeName)...").font(.caption).foregroundColor(.white.opacity(0.7))
                }
            }
            
            if showControls {
                VStack {
                    HStack {
                        Button { 
                            NguonCWebView.activeWebView?.stopLoading()
                            dismiss() 
                        } label: {
                            Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                .padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                        Spacer()
                        Text(episodeName).font(.subheadline).foregroundColor(.white).lineLimit(1)
                        Spacer()
                        Button {
                            isLandscape.toggle()
                            if let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                ws.requestGeometryUpdate(.iOS(interfaceOrientations: isLandscape ? .portrait : .landscapeRight))
                            }
                        } label: {
                            Image(systemName: "rotate.right").font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white).padding(8).background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 50)
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.2)).frame(height: 4)
                                Capsule().fill(.white).frame(width: max(4, geo.size.width * CGFloat(min(max(currentTime / max(duration, 1), 0), 1))), height: 4)
                            }
                        }.frame(height: 20)
                        
                        HStack {
                            Text(formatTime(currentTime)).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.5))
                            Spacer()
                            Text(formatTime(duration)).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.5))
                        }
                        
                        HStack(spacing: 50) {
                            Button { let newTime = max(currentTime - 10, 0); seekTo(newTime) } label: {
                                Image(systemName: "gobackward.10").font(.system(size: 26)).foregroundColor(.white)
                            }
                            Button { isPlaying.toggle(); togglePlay() } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill").font(.system(size: 36)).foregroundColor(.white)
                            }
                            Button { let newTime = min(currentTime + 10, duration); seekTo(newTime) } label: {
                                Image(systemName: "goforward.10").font(.system(size: 26)).foregroundColor(.white)
                            }
                            if !servers.isEmpty {
                                Button { showServerPicker = true } label: {
                                    VStack(spacing: 2) {
                                        Image(systemName: "list.bullet").font(.system(size: 20))
                                        Text("Server").font(.system(size: 9))
                                    }.foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 30)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                }
            }
            
            if showServerPicker {
                Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { showServerPicker = false }
                VStack(spacing: 10) {
                    Text("Chọn server").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    ForEach(servers, id: \.0) { name, url in
                        Button {
                            currentURL = url; currentServerName = name; showServerPicker = false
                            isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isLoading = false }
                        } label: {
                            Text(name).font(.system(size: 13))
                                .foregroundColor(currentServerName == name ? .black : .white)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(currentServerName == name ? Color.white : Color.white.opacity(0.08)))
                        }
                    }
                }
                .padding(18).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.95)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 0.5)).frame(width: 240)
            }
        }
        .statusBarHidden()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isLoading = false }
            showControls = true
            resetControlsTimer()
        }
    }
    
    func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) { showControls = false }
        }
    }
    
    func togglePlay() {
        NguonCWebView.activeWebView?.evaluateJavaScript("var v=document.querySelector('video'); if(v) { if(v.paused) v.play(); else v.pause(); }")
    }
    
    func seekTo(_ time: Double) {
        NguonCWebView.activeWebView?.evaluateJavaScript("var v=document.querySelector('video'); if(v) { v.currentTime=\(time); }")
    }
    
    func formatTime(_ s: Double) -> String {
        let m = Int(s) / 60; let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}

struct NguonCWebView: UIViewRepresentable {
    let url: URL
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    @Binding var duration: Double
    static weak var activeWebView: WKWebView?
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let pref = WKWebpagePreferences()
        pref.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pref
        
        let script = WKUserScript(source: """
    function setup() {
        var video = document.querySelector('video');
        if (video) {
            video.controls = false;
            video.setAttribute('playsinline', 'true');
            video.setAttribute('webkit-playsinline', 'true');
            video.style.width = '100%';
            video.style.height = '100%';
            video.style.position = 'fixed';
            video.style.top = '0';
            video.style.left = '0';
            video.style.zIndex = '9999';
            video.style.backgroundColor = 'black';
            video.play();
        }
        document.body.style.margin = '0';
        document.body.style.padding = '0';
        document.body.style.backgroundColor = 'black';
        document.body.style.overflow = 'hidden';
    }
    document.addEventListener('dblclick', function(e) { e.preventDefault(); });
    setTimeout(setup, 1000);
    setInterval(function() {
        var v = document.querySelector('video');
        if (v) {
            window.webkit.messageHandlers.timeUpdate.postMessage({
                currentTime: v.currentTime,
                duration: v.duration || 1,
                paused: v.paused
            });
        }
    }, 500);
    """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        config.userContentController.add(context.coordinator, name: "timeUpdate")
        
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.backgroundColor = .black
        wv.isOpaque = false
        wv.scrollView.bounces = false
        wv.navigationDelegate = context.coordinator
        wv.load(URLRequest(url: url))
        NguonCWebView.activeWebView = wv
        return wv
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: NguonCWebView
        init(parent: NguonCWebView) { self.parent = parent }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.targetFrame == nil { decisionHandler(.cancel); return }
            decisionHandler(.allow)
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("var video = document.querySelector('video'); if (video) { video.play(); }")
        }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "timeUpdate", let dict = message.body as? [String: Any] {
                DispatchQueue.main.async {
                    self.parent.currentTime = dict["currentTime"] as? Double ?? 0
                    self.parent.duration = dict["duration"] as? Double ?? 1
                    self.parent.isPlaying = !(dict["paused"] as? Bool ?? false)
                }
            }
        }
    }
}