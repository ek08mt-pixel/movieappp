import SwiftUI
import WebKit

struct NguonCPlayerView: View {
    let embedURL: URL
    let episodeName: String
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            NguonCWebView(url: embedURL)
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial.opacity(0.4))
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            )
                    }
                    Spacer()
                    Text(episodeName)
                        .font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Spacer().frame(width: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
                Spacer()
            }
        }
        .statusBarHidden()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isLoading = false
            }
        }
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
        
        // JS nhẹ: chỉ tự động play, không ẩn gì cả
        let script = WKUserScript(
            source: """
            setTimeout(function() {
                var video = document.querySelector('video');
                if (video) {
                    video.setAttribute('playsinline', 'true');
                    video.setAttribute('webkit-playsinline', 'true');
                    video.controls = true;
                    video.play();
                }
            }, 1500);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
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