import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @Environment(\.dismiss) var dismiss
    
    let avatars = ["person.circle.fill", "person.crop.circle.fill", "face.smiling.fill", "star.circle.fill", "heart.circle.fill", "bolt.circle.fill", "moon.circle.fill", "sun.max.circle.fill"]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Tài khoản")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 60)
                    
                    if appState.isLoggedIn {
                        // Avatar
                        VStack(spacing: 12) {
                            if let data = appState.avatarImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90).clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            } else {
                                Image(systemName: appState.selectedAvatar)
                                    .font(.system(size: 50)).foregroundColor(.white)
                                    .frame(width: 90, height: 90)
                                    .background(Circle().fill(.ultraThinMaterial))
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            }
                            
                            HStack(spacing: 16) {
                                Button("Album") { showImagePicker = true }
                                    .font(.caption).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(.ultraThinMaterial))
                                Menu {
                                    ForEach(avatars, id: \.self) { av in
                                        Button { appState.selectedAvatar = av; appState.avatarImageData = nil; appState.save() } label: {
                                            Label(av, systemImage: av)
                                        }
                                    }
                                } label: {
                                    Text("Avatar có sẵn").font(.caption).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Capsule().fill(.ultraThinMaterial))
                                }
                            }
                        }
                        
                        // Nickname
                        VStack(spacing: 8) {
                            if isEditingName {
                                HStack(spacing: 8) {
                                    TextField("Tên của bạn", text: $tempName)
                                        .textFieldStyle(.plain).foregroundColor(.white)
                                        .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                                    Button("Lưu") {
                                        appState.nickname = tempName
                                        appState.save()
                                        isEditingName = false
                                    }
                                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(Capsule().fill(.ultraThinMaterial))
                                }.padding(.horizontal, 30)
                            } else {
                                Button {
                                    tempName = appState.nickname
                                    isEditingName = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(appState.nickname.isEmpty ? "Chưa đặt tên" : appState.nickname)
                                            .font(.headline).foregroundColor(.white)
                                        Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        
                        Text(appState.email)
                            .font(.caption).foregroundColor(.gray)
                        
                        Button {
                            withAnimation { appState.logout() }
                        } label: {
                            Text("Đăng xuất").font(.caption).fontWeight(.medium).foregroundColor(.red)
                                .padding(.horizontal, 24).padding(.vertical, 10)
                                .background(Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1))
                        }
                    } else {
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.2)
                        
                        VStack(spacing: 16) {
                            Text("Đăng nhập để đồng bộ danh sách phim yêu thích trên mọi thiết bị")
                                .font(.caption).foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                switch result {
                                case .success(let auth):
                                    appState.isLoggedIn = true
                                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                        appState.email = credential.email ?? "Apple User"
                                        appState.nickname = credential.fullName?.givenName ?? ""
                                    }
                                    appState.save()
                                case .failure: break
                                }
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .clipShape(Capsule())
                            .padding(.horizontal, 30)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            
                            Button {
                                withAnimation { appState.isLoggedIn = true; appState.email = "user@gmail.com"; appState.save() }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "envelope.fill").font(.system(size: 16))
                                    Text("Đăng nhập với Gmail").font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Capsule().fill(.ultraThinMaterial))
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                        }
                        
                        Spacer().frame(height: UIScreen.main.bounds.height * 0.2)
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    )
            }
            .padding(.top, 54)
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $inputImage)
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

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController(); picker.delegate = context.coordinator; return picker
    }
    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage { parent.image = uiImage }
            parent.dismiss()
        }
    }
}