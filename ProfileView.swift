import SwiftUI

// MARK: - ProfileView (Tab Me)
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @State private var showAuth = false
    @State private var showAchievements = false
    
    let avatars = ["person.circle.fill", "person.crop.circle.fill", "face.smiling.fill",
                   "star.circle.fill", "heart.circle.fill", "bolt.circle.fill",
                   "moon.circle.fill", "sun.max.circle.fill"]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            if appState.isLoggedIn {
                VStack(spacing: 0) {
                    // MARK: - Header: Avatar + Name + Rank
                    HStack(alignment: .center, spacing: 14) {
                        // Avatar + nút bút chì
                        ZStack(alignment: .bottomTrailing) {
                            if let data = appState.avatarImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                            } else {
                                Image(systemName: appState.selectedAvatar)
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                                    .background(Circle().fill(.ultraThinMaterial))
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                            }
                            
                            // Nút bút chì đổi avt
                            Button {
                                showImagePicker = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial.opacity(0.8))
                                        .frame(width: 24, height: 24)
                                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                                    Text("✎")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 4, y: 4)
                        }
                        
                        // Tên + Rank
                        VStack(alignment: .leading, spacing: 4) {
                            // Tên + bút chì
                            HStack(spacing: 6) {
                                if isEditingName {
                                    HStack(spacing: 6) {
                                        TextField("Tên của bạn", text: $tempName)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(.white)
                                            .font(.system(size: 18, weight: .bold))
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 10)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial.opacity(0.4)))
                                            .frame(width: 160)
                                        Button {
                                            appState.nickname = tempName
                                            appState.save()
                                            isEditingName = false
                                        } label: {
                                            Text("✓")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.green)
                                        }
                                    }
                                } else {
                                    Text(appState.nickname.isEmpty ? "Chưa đặt tên" : appState.nickname)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Button {
                                        tempName = appState.nickname
                                        isEditingName = true
                                    } label: {
                                        Text("✎")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            // Settings
NavigationLink(destination: SettingsView()) {
    HStack(spacing: 10) {
        Text("⚙")
            .font(.system(size: 20))
        Text("Cài đặt")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
        Spacer()
        Text("›")
            .font(.system(size: 16, weight: .light))
            .foregroundColor(.gray)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial.opacity(0.3))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 0.5))
    )
}
.padding(.horizontal, 20)
.padding(.top, 12)
                            // Danh hiệu - bấm vào mở AchievementView
                            Button {
                                AchievementManager.shared.refresh(from: appState)
                                showAchievements = true
                            } label: {
                                let rank = AchievementManager.shared.userRankData.currentRank
                                HStack(spacing: 4) {
                                    Text(rank.shortName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(rank.color)
                                    Text("Level \(AchievementManager.shared.userRankData.level)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                    Text("›")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(rank.color.opacity(0.12))
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // MARK: - Giữa: Tạm để trống (sẽ thêm sau)
                    // Không gian giữa để trống
                    
                    Spacer()
                    
                    // MARK: - Footer: Đăng xuất
                    Button {
                        withAnimation { appState.logout() }
                    } label: {
                        Text("Đăng xuất")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.bottom, 120)
                }
            } else {
                // Chưa đăng nhập
                VStack(spacing: 16) {
                    Spacer()
                    Text("Đăng nhập để đồng bộ dữ liệu")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button {
                        showAuth = true
                    } label: {
                        HStack(spacing: 10) {
                            Text("✉")
                                .font(.system(size: 18))
                            Text("Tiếp tục với Email")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 30)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $inputImage) }
        .sheet(isPresented: $showAuth) { SmartAuthView { email, password in
            appState.smartLogin(email: email, password: password)
            showAuth = false
        } }
        .fullScreenCover(isPresented: $showAchievements) {
            AchievementView()
        }
        .onChange(of: inputImage) { img in
            if let img = img, let data = img.jpegData(compressionQuality: 0.7) {
                appState.avatarImageData = data
                appState.selectedAvatar = ""
                appState.save()
            }
        }
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