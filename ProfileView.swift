import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var langManager: LanguageManager
    @State private var showEditName = false
    @State private var showLogin = false
    @State private var loginName = ""
    @State private var loginPassword = ""
    @State private var confirmPassword = ""
    
    let avatars = ["person.fill", "cat.fill", "dog.fill", "rabbit.fill", "fish.fill", "pawprint.fill", "heart.fill", "star.fill", "crown.fill", "sparkles"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Menu {
                            ForEach(avatars, id: \.self) { icon in
                                Button {
                                    appState.selectedAvatar = icon
                                    appState.saveToDisk()
                                } label: {
                                    Label(icon, systemImage: icon)
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.thinMaterial)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.2), radius: 8)
                                
                                Image(systemName: appState.selectedAvatar)
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 35))
                            }
                        }
                        .padding(.top, 20)
                        
                        if appState.isLoggedIn {
                            Text(appState.userName)
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                            Button("Đăng xuất") {
                                appState.isLoggedIn = false
                                appState.userName = ""
                                appState.saveToDisk()
                            }
                            .foregroundColor(.red).font(.caption)
                        } else {
                            Button {
                                loginName = ""; loginPassword = ""; confirmPassword = ""
                                showLogin = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.key.fill")
                                    Text("Đăng nhập / Tạo tài khoản")
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(Capsule().fill(.ultraThinMaterial))
                            }
                        }
                        
                        // Stats
                        NavigationLink(destination: StatsView()) {
                            HStack {
                                Image(systemName: "chart.bar.fill").foregroundColor(.orange)
                                Text("Xem thống kê của bạn").foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text("\(appState.favorites.count)").font(.title2).fontWeight(.bold).foregroundColor(.white)
                                Text("Yêu thích").font(.caption).foregroundColor(.gray)
                            }.frame(maxWidth: .infinity)
                            VStack(spacing: 4) {
                                Text("\(appState.watchHistory.count)").font(.title2).fontWeight(.bold).foregroundColor(.white)
                                Text("Đã xem").font(.caption).foregroundColor(.gray)
                            }.frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                            ProfileRow(icon: "pencil", title: "Đổi tên hiển thị") { showEditName = true }
                            Divider().background(Color.white.opacity(0.1))
                            
                            NavigationLink(destination: LanguageSelectionView()) {
                                HStack {
                                    Image(systemName: "globe").foregroundColor(.white.opacity(0.6)).frame(width: 24)
                                    Text("Ngôn ngữ").foregroundColor(.white)
                                    Spacer()
                                    Text(langManager.currentLanguage.displayName).foregroundColor(.gray).font(.caption)
                                    Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
                                }.padding()
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            // Director search
                            NavigationLink(destination: DirectorSearchView()) {
                                HStack {
                                    Image(systemName: "megaphone.fill").foregroundColor(.white.opacity(0.6)).frame(width: 24)
                                    Text("Tìm đạo diễn").foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
                                }.padding()
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            ProfileRow(icon: "doc.text", title: "Chính sách & Điều khoản") {}
                            Divider().background(Color.white.opacity(0.1))
                            ProfileRow(icon: "info.circle", title: "Phiên bản 1.0") {}
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                        .padding(.horizontal)
                        
                        Text("Made with ♥ by emmewchamchi")
                            .font(.system(size: 11)).foregroundColor(.gray.opacity(0.5))
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Tài khoản")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showEditName) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        TextField("Nhập tên mới", text: $loginName)
                            .textFieldStyle(.plain).foregroundColor(.white).padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                        Button("Lưu") {
                            if !loginName.isEmpty { appState.userName = loginName; appState.saveToDisk() }
                            showEditName = false
                        }
                        .fontWeight(.bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.2)))
                    }.padding()
                }
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Hủy") { showEditName = false } } }
            }
        }
        .sheet(isPresented: $showLogin) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Đăng nhập / Đăng ký").font(.title2).fontWeight(.bold).foregroundColor(.white)
                            TextField("Tên người dùng", text: $loginName).textFieldStyle(.plain).foregroundColor(.white).padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                            SecureField("Mật khẩu", text: $loginPassword).textFieldStyle(.plain).foregroundColor(.white).padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                            SecureField("Xác nhận mật khẩu", text: $confirmPassword).textFieldStyle(.plain).foregroundColor(.white).padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                            Button {
                                if !loginName.isEmpty && loginPassword == confirmPassword && !loginPassword.isEmpty {
                                    appState.userName = loginName; appState.isLoggedIn = true; appState.saveToDisk(); showLogin = false
                                }
                            } label: {
                                Text(loginPassword.isEmpty ? "Đăng ký" : "Xác nhận").fontWeight(.bold).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding()
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(!loginName.isEmpty && loginPassword == confirmPassword && !loginPassword.isEmpty ? Color.blue.opacity(0.6) : Color.gray.opacity(0.3)))
                            }
                            .disabled(loginName.isEmpty || loginPassword != confirmPassword || loginPassword.isEmpty)
                        }.padding()
                    }
                }
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Hủy") { showLogin = false } } }
            }
        }
    }
}

struct ProfileRow: View {
    let icon: String; let title: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(.white.opacity(0.6)).frame(width: 24)
                Text(title).foregroundColor(.white); Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
            }.padding()
        }
    }
}