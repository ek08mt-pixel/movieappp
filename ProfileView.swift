import SwiftUI
import WebKit

// MARK: - Google Auth WebView (Liquid Glass)
struct GoogleAuthWebView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showWebView = false
    let onSuccess: (String, String, String?) -> Void // googleId, name, avatarURL
    
    private let clientId = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    private let redirectUri = "com.emmew.app:/oauth2callback"
    
    var authURL: URL {
        URL(string: "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=code&scope=openid%20profile%20email&access_type=offline&prompt=consent")!
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
                
                GoogleWebView(url: authURL, redirectUri: redirectUri) { code in
                    // Exchange code for id_token via Google API
                    exchangeCodeForToken(code: code) { googleId, name, avatar in
                        onSuccess(googleId, name, avatar)
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.75)
            .background(.ultraThinMaterial.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        }
    }
    
    func exchangeCodeForToken(code: String, completion: @escaping (String, String, String?) -> Void) {
        // Dùng Firebase Auth REST API hoặc Google Token endpoint
        // Demo: parse id_token từ Google (cần client secret)
        // Tạm thời dùng mock data nếu chưa có client secret
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "code=\(code)&client_id=\(clientId)&redirect_uri=\(redirectUri)&grant_type=authorization_code"
        req.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let idToken = json["id_token"] as? String else {
                completion("google_\(UUID().uuidString)", "Google User", nil)
                return
            }
            
            // Decode JWT id_token để lấy thông tin user
            let parts = idToken.components(separatedBy: ".")
            if parts.count >= 2,
               let payload = Data(base64Encoded: parts[1].padding(toLength: ((parts[1].count + 3) / 4) * 4, withPad: "=", startingAt: 0)),
               let userInfo = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] {
                let googleId = userInfo["sub"] as? String ?? UUID().uuidString
                let name = userInfo["name"] as? String ?? "Google User"
                let avatar = userInfo["picture"] as? String
                completion(googleId, name, avatar)
            } else {
                completion("google_\(UUID().uuidString)", "Google User", nil)
            }
        }.resume()
    }
}

// MARK: - WebView for Google OAuth
struct GoogleWebView: UIViewRepresentable {
    let url: URL
    let redirectUri: String
    let onCode: (String) -> Void
    
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
        let parent: GoogleWebView
        init(_ parent: GoogleWebView) { self.parent = parent }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url?.absoluteString,
               url.hasPrefix(parent.redirectUri),
               let components = URLComponents(string: url),
               let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                parent.onCode(code)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - ProfileView (ĐÃ SỬA: Thêm Google Login)
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @State private var showAuth = false
    @State private var showGoogleAuth = false
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
                            } else if let avatarURL = appState.googleAvatarURL, let url = URL(string: avatarURL) {
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
                                HStack(spacing: 8) {
                                    TextField("Tên của bạn", text: $tempName).textFieldStyle(.plain).foregroundColor(.white).padding(10).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                                    Button("Lưu") { appState.nickname = tempName; appState.save(); isEditingName = false }.font(.caption).fontWeight(.bold).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 10).background(Capsule().fill(.ultraThinMaterial))
                                }.padding(.horizontal, 30)
                            } else {
                                Button { tempName = appState.nickname; isEditingName = true } label: { HStack(spacing: 6) { Text(appState.nickname.isEmpty ? "Chưa đặt tên" : appState.nickname).font(.headline).foregroundColor(.white); Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(.gray) } }
                            }
                        }
                        
                        Text(appState.email).font(.caption).foregroundColor(.gray)
                        
                        Button { withAnimation { appState.logout() } } label: { Text("Đăng xuất").font(.caption).fontWeight(.medium).foregroundColor(.red).padding(.horizontal, 24).padding(.vertical, 10).background(Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1)) }
                    } else {
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.12)
                        
                        VStack(spacing: 16) {
                            Text("Đăng nhập để đồng bộ dữ liệu").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                            
                            // Google Login Button
                            Button { showGoogleAuth = true } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "g.circle.fill").font(.system(size: 22))
                                    Text("Tiếp tục với Google").font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Capsule().fill(.ultraThinMaterial))
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            }.padding(.horizontal, 30)
                            
                            // Email Login Button
                            Button { showAuth = true } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "envelope.fill").font(.system(size: 18))
                                    Text("Tiếp tục với Email").font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.7)).frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(Capsule().fill(.white.opacity(0.05)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
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
        .fullScreenCover(isPresented: $showGoogleAuth) {
            GoogleAuthWebView { googleId, name, avatarURL in
                appState.googleLogin(googleId: googleId, name: name, avatarURL: avatarURL)
            }
        }
        .onChange(of: inputImage) { img in if let img = img, let data = img.jpegData(compressionQuality: 0.7) { appState.avatarImageData = data; appState.selectedAvatar = ""; appState.save() } }
    }
}

// Giữ nguyên SmartAuthView, ImagePicker
struct SmartAuthView: View {
    @State private var email = ""; @State private var password = ""; @State private var errorMsg = ""
    let onAuth: (String, String) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack { Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Đăng nhập").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("Nhập email và mật khẩu.\nNếu chưa có tài khoản, hệ thống sẽ tự tạo mới.").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 30)
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