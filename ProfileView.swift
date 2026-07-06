import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @State private var showRegister = false
    @State private var showLogin = false
    @Environment(\.dismiss) var dismiss
    
    let avatars = ["person.circle.fill", "person.crop.circle.fill", "face.smiling.fill",
                   "star.circle.fill", "heart.circle.fill", "bolt.circle.fill",
                   "moon.circle.fill", "sun.max.circle.fill"]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Tài khoản")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 60)
                    
                    if appState.isLoggedIn {
                        VStack(spacing: 12) {
                            if let data = appState.avatarImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90).clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            } else {
                                Image(systemName: appState.selectedAvatar).font(.system(size: 50)).foregroundColor(.white)
                                    .frame(width: 90, height: 90).background(Circle().fill(.ultraThinMaterial))
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            }
                            
                            HStack(spacing: 16) {
                                Button("Album") { showImagePicker = true }
                                    .font(.caption).foregroundColor(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(.ultraThinMaterial))
                                Menu {
                                    ForEach(avatars, id: \.self) { av in
                                        Button { appState.selectedAvatar = av; appState.avatarImageData = nil; appState.save() } label: {
                                            Label(av, systemImage: av)
                                        }
                                    }
                                } label: {
                                    Text("Avatar có sẵn").font(.caption).foregroundColor(.white)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Capsule().fill(.ultraThinMaterial))
                                }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            if isEditingName {
                                HStack(spacing: 8) {
                                    TextField("Tên của bạn", text: $tempName)
                                        .textFieldStyle(.plain).foregroundColor(.white)
                                        .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                                    Button("Lưu") {
                                        appState.nickname = tempName; appState.save(); isEditingName = false
                                    }
                                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(Capsule().fill(.ultraThinMaterial))
                                }.padding(.horizontal, 30)
                            } else {
                                Button { tempName = appState.nickname; isEditingName = true } label: {
                                    HStack(spacing: 6) {
                                        Text(appState.nickname.isEmpty ? "Chưa đặt tên" : appState.nickname)
                                            .font(.headline).foregroundColor(.white)
                                        Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        
                        Text(appState.email).font(.caption).foregroundColor(.gray)
                        
                        Button { withAnimation { appState.logout() } } label: {
                            Text("Đăng xuất").font(.caption).fontWeight(.medium).foregroundColor(.red)
                                .padding(.horizontal, 24).padding(.vertical, 10)
                                .background(Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1))
                        }
                    } else {
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.15)
                        
                        VStack(spacing: 16) {
                            Text("Đăng ký hoặc đăng nhập để đồng bộ danh sách phim yêu thích")
                                .font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button { showRegister = true } label: {
                                Text("Đăng ký").font(.headline).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(Capsule().fill(.ultraThinMaterial))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            }.padding(.horizontal, 30)
                            
                            Button { showLogin = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "envelope.fill").font(.system(size: 16))
                                    Text("Đăng nhập với Gmail").font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Capsule().fill(.ultraThinMaterial))
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                            }
                            .padding(.horizontal, 30).padding(.vertical, 10)
                        }
                        
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.15)
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(14)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.3))
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)))
            }.padding(.top, 54).padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $inputImage) }
        .sheet(isPresented: $showRegister) {
            RegisterView { email, password in
                appState.register(email: email, password: password)
                showRegister = false
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView { email, password in
                appState.login(email: email, password: password)
                showLogin = false
            }
        }
        .onChange(of: inputImage) { img in
            if let img = img, let data = img.jpegData(compressionQuality: 0.7) {
                appState.avatarImageData = data; appState.selectedAvatar = ""; appState.save()
            }
        }
    }
}

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    let onRegister: (String, String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Đăng ký").font(.title2).fontWeight(.bold).foregroundColor(.white)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.plain).foregroundColor(.white)
                    .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                    .padding(.horizontal, 30)
                    .keyboardType(.emailAddress).autocapitalization(.none)
                
                SecureField("Mật khẩu", text: $password)
                    .textFieldStyle(.plain).foregroundColor(.white)
                    .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                    .padding(.horizontal, 30)
                
                Button {
                    if email.contains("@") && email.contains(".") && password.count >= 4 {
                        onRegister(email, password)
                    }
                } label: {
                    Text("Đăng ký").font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                }.padding(.horizontal, 30)
                
                Button("Đóng") { dismiss() }.foregroundColor(.gray)
            }
        }
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    let onLogin: (String, String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Đăng nhập").font(.title2).fontWeight(.bold).foregroundColor(.white)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.plain).foregroundColor(.white)
                    .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                    .padding(.horizontal, 30)
                    .keyboardType(.emailAddress).autocapitalization(.none)
                
                SecureField("Mật khẩu", text: $password)
                    .textFieldStyle(.plain).foregroundColor(.white)
                    .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                    .padding(.horizontal, 30)
                
                Button {
                    if email.contains("@") && email.contains(".") && password.count >= 4 {
                        onLogin(email, password)
                    }
                } label: {
                    Text("Đăng nhập").font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                }.padding(.horizontal, 30)
                
                Button("Đóng") { dismiss() }.foregroundColor(.gray)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController(); picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker; init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage { parent.image = uiImage }; parent.dismiss()
        }
    }
}