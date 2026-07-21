import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @AppStorage("userTheme") private var userTheme: String = "dark"
    @AppStorage("seekSeconds") private var seekSeconds: Double = 10
    @State private var showClearCacheAlert = false
    
    private let appVersion = "1.0"
    private let buildNumber = "1"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                        }
                        Spacer()
                        Text("Cài đặt")
                            .font(.title2).fontWeight(.bold).foregroundColor(.white)
                        Spacer()
                        Circle().fill(.clear).frame(width: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    // MARK: - Giao diện
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GIAO DIỆN")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // Ngôn ngữ
                            NavigationLink(destination: LanguageSelectionView()) {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 28)
                                    Text("Ngôn ngữ")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(LanguageManager.shared.currentLanguage.displayName)
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 44)
                            
                            // Theme
                            HStack {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 28)
                                Text("Theme")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $userTheme) {
                                    Text("Tối").tag("dark")
                                    Text("Sáng").tag("light")
                                    Text("Hệ thống").tag("system")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.3)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Phát lại
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PHÁT LẠI")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // Tua thời lượng
                            HStack {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 28)
                                Text("Thời lượng tua")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $seekSeconds) {
                                    Text("5s").tag(5.0)
                                    Text("10s").tag(10.0)
                                    Text("15s").tag(15.0)
                                    Text("20s").tag(20.0)
                                    Text("25s").tag(25.0)
                                    Text("30s").tag(30.0)
                                }
                                .pickerStyle(.menu)
                                .tint(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.3)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Dữ liệu
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DỮ LIỆU")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // Xóa cache
                            Button {
                                showClearCacheAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red.opacity(0.7))
                                        .frame(width: 28)
                                    Text("Xóa bộ nhớ đệm")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(formatCacheSize())
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.3)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Thông tin
                    VStack(alignment: .leading, spacing: 4) {
                        Text("THÔNG TIN")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // Info App
                            Button {
                                if let url = URL(string: "https://emew.page.link/about") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 28)
                                    Text("Thông tin ứng dụng")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 44)
                            
                            // Điều khoản
                            Button {
                                if let url = URL(string: "https://emew.page.link/terms") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 28)
                                    Text("Điều khoản & Điều kiện")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 44)
                            
                            // Chính sách bảo mật
                            Button {
                                if let url = URL(string: "https://emew.page.link/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "hand.raised")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 28)
                                    Text("Chính sách bảo mật")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 44)
                            
                            // Version
                            HStack {
                                Image(systemName: "apps.iphone")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 28)
                                Text("Phiên bản")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("EMCC \(appVersion) (\(buildNumber))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.3)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 60)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Xóa bộ nhớ đệm?", isPresented: $showClearCacheAlert) {
            Button("Hủy", role: .cancel) { }
            Button("Xóa", role: .destructive) { clearCache() }
        } message: {
            Text("Tất cả dữ liệu cache sẽ bị xóa. Dữ liệu quan trọng sẽ được giữ lại.")
        }
    }
    
    func formatCacheSize() -> String {
        let cacheSize = URLCache.shared.currentDiskUsage
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(cacheSize))
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        ImageCache.shared.clearCache()
        UserDefaults.standard.removeObject(forKey: "phimapi_stream_cache")
    }
}