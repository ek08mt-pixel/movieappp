import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @State private var showAuth = false
    @State private var showAchievements = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            if appState.isLoggedIn {
                VStack(spacing: 0) {
                    // Header
                    HStack(alignment: .center, spacing: 14) {
                        // Avatar + bút chì
                        ZStack(alignment: .bottomTrailing) {
                            if let data = appState.avatarImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))
                                    .shadow(color: .white.opacity(0.15), radius: 8)
                            } else {
                                Image(systemName: appState.selectedAvatar)
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                                    .background(Circle().fill(.ultraThinMaterial))
                                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))
                                    .shadow(color: .white.opacity(0.15), radius: 8)
                            }
                            
                            // Bút chì + gạch dưới
                            Button {
                                showImagePicker = true
                            } label: {
                                ZStack(alignment: .bottomTrailing) {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                    Text("✎")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .overlay(alignment: .bottom) {
                                Text("_")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 8, y: 12)
                            }
                        }
                        
                        // Tên + Danh hiệu
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                if isEditingName {
                                    HStack(spacing: 4) {
                                        TextField("Tên", text: $tempName)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(.white)
                                            .font(.system(size: 18, weight: .bold))
                                            .frame(width: 120)
                                        Button {
                                            appState.nickname = tempName
                                            appState.save()
                                            isEditingName = false
                                        } label: {
                                            Text("✓")
                                                .font(.system(size: 12, weight: .bold))
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
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            Button {
                                AchievementManager.shared.refresh(from: appState)
                                showAchievements = true
                            } label: {
                                let rank = AchievementManager.shared.userRankData.currentRank
                                HStack(spacing: 4) {
                                    Text(rank.shortName)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(rank.color)
                                    Text("Lv.\(AchievementManager.shared.userRankData.level)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Text("›")
                                        .font(.system(size: 9))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(rank.color.opacity(0.12)))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Đăng xuất
                    Button {
                        withAnimation { appState.logout() }
                    } label: {
                        Text("Đăng xuất")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red.opacity(0.7))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color.red.opacity(0.25), lineWidth: 0.8)
                            )
                    }
                    .padding(.bottom, 120)
                }
                
                // Nút Settings góc phải trên - chỉ icon, không khung
                VStack {
                    HStack {
                        Spacer()
                        NavigationLink(destination: SettingsView()) {
                            Text("⚙")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.top, 54)
                    .padding(.trailing, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Text("Đăng nhập để đồng bộ dữ liệu")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button {
                        showAuth = true
                    } label: {
                        Text("Tiếp tục với Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $inputImage) }
        .sheet(isPresented: $showAuth) { SmartAuthView { email, password in
            appState.smartLogin(email: email, password: password)
            showAuth = false
        }}
        .fullScreenCover(isPresented: $showAchievements) { AchievementView() }
        .onChange(of: inputImage) { img in
            if let img = img, let data = img.jpegData(compressionQuality: 0.7) {
                appState.avatarImageData = data
                appState.selectedAvatar = ""
                appState.save()
            }
        }
    }
}