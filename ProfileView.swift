import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditName = false
    @State private var newName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white.opacity(0.7)).font(.system(size: 35))
                            )
                            .padding(.top, 20)
                        
                        // Tên
                        if appState.isLoggedIn {
                            Text(appState.userName)
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                        } else {
                            Button("Đăng nhập") {
                                newName = ""
                                showEditName = true
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Thống kê
                        HStack(spacing: 0) {
                            StatBox(value: "\(appState.favorites.count)", label: "Yêu thích")
                            StatBox(value: "\(appState.watchHistory.count)", label: "Đã xem")
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                            ProfileRow(icon: "pencil", title: "Đổi tên") { showEditName = true }
                            ProfileRow(icon: "doc.text", title: "Chính sách & Điều khoản") {}
                            ProfileRow(icon: "info.circle", title: "Phiên bản 1.0") {}
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Credit
                        Text("Made with ♥ by emmewchamchi")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Tài khoản")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showEditName) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        TextField("Nhập tên", text: $newName)
                            .textFieldStyle(.plain).foregroundColor(.white).padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                        
                        Button("Lưu") {
                            appState.userName = newName
                            appState.isLoggedIn = true
                            showEditName = false
                        }
                        .fontWeight(.bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.2)))
                    }
                    .padding()
                }
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Hủy") { showEditName = false } } }
            }
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(.white.opacity(0.6)).frame(width: 24)
                Text(title).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
            }
            .padding()
        }
    }
}
