import SwiftUI
import WebKit
import CommonCrypto

// MARK: - Telegram Auth WebView (Liquid Glass)
struct TelegramAuthWebView: View {
    @Environment(\.dismiss) var dismiss
    let onSuccess: (String, String, String?) -> Void
    
    private let botToken = "8819940584:AAFoBSqOZd_-jxNcO3pTCYF16aGcI-qSg9s"
    private let botUsername = "Emmew_bot"
    
    var authURL: URL {
        URL(string: "https://oauth.telegram.org/auth?bot_id=\(botToken.components(separatedBy: ":").first ?? "")&origin=\(botUsername)&request_access=write")!
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { dismiss() }
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundColor(.white.opacity(0.7))
                    }.padding(16)
                }
                TelegramWebView(url: authURL) { userData in
                    if let data = userData, verifyTelegramData(data) {
                        let id = data["id"] as? String ?? "\(data["id"] as? Int ?? 0)"
                        let name = (data["first_name"] as? String) ?? "Telegram User"
                        let avatar = data["photo_url"] as? String
                        onSuccess(id, name, avatar)
                    } else {
                        onSuccess("\(UUID().uuidString)", "Telegram User", nil)
                    }
                    dismiss()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.7)
            .background(.ultraThinMaterial.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        }
    }
    
    func verifyTelegramData(_ data: [String: Any]) -> Bool {
        guard let hash = data["hash"] as? String else { return false }
        var checkString = ""
        let sortedKeys = data.keys.filter { $0 != "hash" }.sorted()
        for key in sortedKeys {
            if let value = data[key] { checkString += "\(key)=\(value)\n" }
        }
        checkString = String(checkString.dropLast())
        guard let secretKey = hmacSHA256(key: "WebAppData", message: botToken) else { return false }
        guard let computedHash = hmacSHA256(key: secretKey.base64EncodedString(), message: checkString) else { return false }
        return computedHash.hexString() == hash
    }
    
    func hmacSHA256(key: String, message: String) -> Data? {
        guard let keyData = key.data(using: .utf8), let msgData = message.data(using: .utf8) else { return nil }
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            msgData.withUnsafeBytes { msgBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, keyData.count, msgBytes.baseAddress, msgData.count, &hmac)
            }
        }
        return Data(hmac)
    }
}

extension Data {
    func hexString() -> String { map { String(format: "%02hhx", $0) }.joined() }
}

// MARK: - Telegram WebView
struct TelegramWebView: UIViewRepresentable {
    let url: URL
    let onCallback: ([String: Any]?) -> Void
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        wv.load(URLRequest(url: url))
        return wv
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: TelegramWebView
        init(_ parent: TelegramWebView) { self.parent = parent }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url?.absoluteString,
               url.contains("tgWebAppData=") || url.contains("hash=") {
                if let components = URLComponents(string: url),
                   let fragment = components.fragment {
                    let params = fragment.components(separatedBy: "&")
                    var dict: [String: Any] = [:]
                    for param in params {
                        let kv = param.components(separatedBy: "=")
                        if kv.count == 2 { dict[kv[0]] = kv[1].removingPercentEncoding ?? kv[1] }
                    }
                    parent.onCallback(dict)
                    decisionHandler(.cancel)
                    return
                }
                if let queryItems = URLComponents(string: url)?.queryItems {
                    var dict: [String: Any] = [:]
                    for item in queryItems { dict[item.name] = item.value }
                    parent.onCallback(dict)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @State private var showAuth = false
    @State private var showTelegramAuth = false
    @Environment(\.dismiss) var dismiss
    
    let avatars = ["person.circle.fill", "person.crop.circle.fill", "face.smiling.fill",
                   "star.circle.fill", "heart.circle.fill", "bolt.circle.fill",
                   "moon.circle.fill", "sun.max.circle.fill"]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Tài khoản").font(.title2).fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .center).padding(.top, 60)
                    
                    if appState.isLoggedIn {
                        VStack(spacing: 12) {
                            if let data = appState.avatarImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill).frame(width: 90, height: 90).clipShape(Circle()).overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            } else if let avatarURL = appState.telegramAvatarURL, let url = URL(string: avatarURL) {
                                CachedAsyncImage(url: url, size: .detail).aspectRatio(contentMode: .fill).frame(width: 90, height: 90).clipShape(Circle()).overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            } else {
                                Image(systemName: appState.selectedAvatar).font(.system(size: 50)).foregroundColor(.white).frame(width: 90, height: 90).background(Circle().fill(.ultraThinMaterial)).overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            }
                            
                            HStack(spacing: 16) {
                                Button("Album") { showImagePicker = true }.font(.caption).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial))
                                Menu { ForEach(avatars, id: \.self) { av in Button { appState.selectedAvatar = av; appState.avatarImageData = nil; appState.save() } label: { Label(av, systemImage: av) } } } label: { Text("Avatar có sẵn").font(.caption).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial)) }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            if isEditingName {
                                HStack(spacing: 8) { TextField("Tên của bạn", text: $tempName).textFieldStyle(.plain).foregroundColor(.white).padding(10).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)); Button("Lưu") { appState.nickname = tempName; appState.save(); isEditingName = false }.font(.caption).fontWeight(.bold).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial)) }.padding(.horizontal, 30)
                            } else {
                                Button { tempName = appState.nickname; isEditingName = true } label: { HStack(spacing: 6) { Text(appState.nickname.isEmpty ? "Chưa đặt tên" : appState.nickname).font(.headline).foregroundColor(.white); Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(.gray) } }
                            }
                        }
                        
                        Text(appState.email.prefix(20) + (appState.email.count > 20 ? "..." : "")).font(.caption).foregroundColor(.gray)
                        
                        Button { withAnimation { appState.logout() } } label: { Text("Đăng xuất").font(.caption).fontWeight(.medium).foregroundColor(.red).padding(.horizontal, 24).padding(.vertical, 10).background(Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1)) }
                    } else {
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.12)
                        VStack(spacing: 16) {
                            Text("Đăng nhập để đồng bộ dữ liệu").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                            
                            Button { showTelegramAuth = true } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "paperplane.circle.fill").font(.system(size: 22))
                                    Text("Tiếp tục với Telegram").font(.system(size: 16, weight: .medium))
                                }.foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(Capsule().fill(.ultraThinMaterial)).overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            }.padding(.horizontal, 30)
                            
                            Button { showAuth = true } label: {
                                HStack(spacing: 10) { Image(systemName: "envelope.fill").font(.system(size: 18)); Text("Tiếp tục với Email").font(.system(size: 16, weight: .medium)) }
                                .foregroundColor(.white.opacity(0.7)).frame(maxWidth: .infinity).padding(.vertical, 12).background(Capsule().fill(.white.opacity(0.05))).overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                            }.padding(.horizontal, 30)
                        }
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.15)
                    }
                    Spacer().frame(height: 40)
                }
            }
            
            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.3)).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $inputImage) }
        .sheet(isPresented: $showAuth) { SmartAuthView { email, password in appState.smartLogin(email: email, password: password); showAuth = false } }
        .fullScreenCover(isPresented: $showTelegramAuth) {
            TelegramAuthWebView { telegramId, name, avatarURL in
                appState.telegramLogin(telegramId: telegramId, name: name, avatarURL: avatarURL)
            }
        }
        .onChange(of: inputImage) { img in if let img = img, let data = img.jpegData(compressionQuality: 0.7) { appState.avatarImageData = data; appState.selectedAvatar = ""; appState.save() } }
    }
}

struct SmartAuthView: View {
    @State private var email = ""; @State private var password = ""; @State private var errorMsg = ""
    let onAuth: (String, String) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack { Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 20) { Text("Đăng nhập").font(.title2).fontWeight(.bold).foregroundColor(.white); Text("Nhập email và mật khẩu.\nNếu chưa có tài khoản, hệ thống sẽ tự tạo mới.").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 30)
                TextField("Email", text: $email).textFieldStyle(.plain).foregroundColor(.white).padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)).padding(.horizontal, 30).keyboardType(.emailAddress).autocapitalization(.none)
                SecureField("Mật khẩu", text: $password).textFieldStyle(.plain).foregroundColor(.white).padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)).padding(.horizontal, 30)
                if !errorMsg.isEmpty { Text(errorMsg).font(.caption).foregroundColor(.red) }
                Button { guard email.contains("@"), email.contains("."), password.count >= 4 else { errorMsg = "Email hoặc mật khẩu không hợp lệ"; return }; onAuth(email, password) } label: { Text("Tiếp tục").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(Capsule().fill(.ultraThinMaterial)).overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5)) }.padding(.horizontal, 30)
                Button("Đóng") { dismiss() }.foregroundColor(.gray)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?; @Environment(\.dismiss) var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController { let picker = UIImagePickerController(); picker.delegate = context.coordinator; return picker }
    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate { let parent: ImagePicker; init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { if let uiImage = info[.originalImage] as? UIImage { parent.image = uiImage }; parent.dismiss() }
    }
}