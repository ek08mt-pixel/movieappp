import SwiftUI

// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @State private var showAuth = false
    @State private var showTelegramOTP = false
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
                            
                            Button { showTelegramOTP = true } label: {
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
        .sheet(isPresented: $showTelegramOTP) {
            TelegramOTPView { telegramId, name, avatarURL in
                appState.telegramLogin(telegramId: telegramId, name: name, avatarURL: avatarURL)
            }
        }
        .onChange(of: inputImage) { img in if let img = img, let data = img.jpegData(compressionQuality: 0.7) { appState.avatarImageData = data; appState.selectedAvatar = ""; appState.save() } }
    }
}

// MARK: - Telegram OTP View
struct TelegramOTPView: View {
    @Environment(\.dismiss) var dismiss
    @State private var otpCode = ""
    @State private var isLoading = false
    @State private var errorMsg = ""
    let onSuccess: (String, String, String?) -> Void
    
    private let botToken = "8819940584:AAFoBSqOZd_-jxNcO3pTCYF16aGcI-qSg9s"
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Đăng nhập Telegram").font(.title2).fontWeight(.bold).foregroundColor(.white)
                
                Text("1. Mở Telegram, tìm @Emmew_bot\n2. Nhắn /start để nhận mã OTP\n3. Nhập mã bên dưới")
                    .font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                
                TextField("Mã OTP", text: $otpCode)
                    .textFieldStyle(.plain).foregroundColor(.white)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                    .padding(.horizontal, 30)
                    .keyboardType(.numberPad)
                    .onChange(of: otpCode) { newValue in
                        if newValue.count >= 6 {
                            verifyOTP(code: newValue)
                        }
                    }
                
                if !errorMsg.isEmpty { Text(errorMsg).font(.caption).foregroundColor(.red) }
                if isLoading { ProgressView().tint(.white) }
                
                Button { dismiss() } label: { Text("Đóng").foregroundColor(.gray).padding(.top, 10) }
            }
            .padding(.vertical, 40)
        }
    }
    
    func verifyOTP(code: String) {
        isLoading = true; errorMsg = ""
        
        guard let url = URL(string: "https://api.telegram.org/bot\(botToken)/getUpdates?limit=5") else { errorMsg = "Lỗi kết nối"; isLoading = false; return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [[String: Any]] else {
                DispatchQueue.main.async { self.errorMsg = "Không thể kết nối bot"; self.isLoading = false }
                return
            }
            
            for update in result {
                if let message = update["message"] as? [String: Any],
                   let text = message["text"] as? String,
                   text.trimmingCharacters(in: .whitespaces) == code,
                   let from = message["from"] as? [String: Any],
                   let userId = from["id"] as? Int64,
                   let firstName = from["first_name"] as? String {
                    let avatar = from["photo_url"] as? String
                    DispatchQueue.main.async {
                        self.onSuccess("\(userId)", firstName, avatar)
                        self.dismiss()
                    }
                    return
                }
            }
            
            DispatchQueue.main.async { self.errorMsg = "Mã OTP không đúng"; self.isLoading = false }
        }.resume()
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