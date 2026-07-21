import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @AppStorage("userTheme") private var userTheme: String = "dark"
    @AppStorage("seekSeconds") private var seekSeconds: Double = 10
    @State private var showClearCacheAlert = false
    @State private var showInfo = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    
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
                            NavigationLink(destination: LanguageSelectionView()) {
                                HStack {
                                    Image(systemName: "globe").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
                                    Text("Ngôn ngữ").font(.system(size: 15)).foregroundColor(.white)
                                    Spacer()
                                    Text(LanguageManager.shared.currentLanguage.displayName).font(.system(size: 13)).foregroundColor(.gray)
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                            }
                            
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 44)
                            
                            HStack {
                                Image(systemName: "circle.lefthalf.filled").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
                                Text("Theme").font(.system(size: 15)).foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $userTheme) {
                                    Text("Tối").tag("dark")
                                    Text("Sáng").tag("light")
                                    Text("Hệ thống").tag("system")
                                }
                                .pickerStyle(.segmented).frame(width: 180)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
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
                            HStack {
                                Image(systemName: "forward.fill").font(.system(size: 14)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
                                Text("Thời lượng tua").font(.system(size: 15)).foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $seekSeconds) {
                                    Text("5s").tag(5.0)
                                    Text("10s").tag(10.0)
                                    Text("15s").tag(15.0)
                                    Text("20s").tag(20.0)
                                    Text("25s").tag(25.0)
                                    Text("30s").tag(30.0)
                                }
                                .pickerStyle(.menu).tint(.white)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
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
                            Button {
                                showClearCacheAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash").font(.system(size: 16)).foregroundColor(.red.opacity(0.7)).frame(width: 28)
                                    Text("Xóa bộ nhớ đệm").font(.system(size: 15)).foregroundColor(.white)
                                    Spacer()
                                    Text(formatCacheSize()).font(.system(size: 13)).foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
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
                            Button { showInfo = true } label: {
                                settingRow(icon: "info.circle", title: "Thông tin ứng dụng")
                            }
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 44)
                            
                            Button { showTerms = true } label: {
                                settingRow(icon: "doc.text", title: "Điều khoản & Điều kiện")
                            }
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 44)
                            
                            Button { showPrivacy = true } label: {
                                settingRow(icon: "hand.raised", title: "Chính sách bảo mật")
                            }
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 44)
                            
                            HStack {
                                Image(systemName: "apps.iphone").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
                                Text("Phiên bản").font(.system(size: 15)).foregroundColor(.white)
                                Spacer()
                                Text("EMCC \(appVersion) (\(buildNumber))").font(.system(size: 13)).foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
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
            Text("Tất cả dữ liệu cache sẽ bị xóa.")
        }
        .sheet(isPresented: $showInfo) {
            InfoPopupView(title: "Thông tin ứng dụng", content: infoText)
        }
        .sheet(isPresented: $showTerms) {
            InfoPopupView(title: "Điều khoản & Điều kiện", content: termsText)
        }
        .sheet(isPresented: $showPrivacy) {
            InfoPopupView(title: "Chính sách bảo mật", content: privacyText)
        }
    }
    
    func settingRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
            Text(title).font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(.gray)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
    
    func formatCacheSize() -> String {
        URLCache.shared.removeAllCachedResponses()
        return "0 KB"
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        ImageCache.shared.clearCache()
        UserDefaults.standard.removeObject(forKey: "phimapi_stream_cache")
    }
    
    var infoText: String {
        """
        EMCC - Ứng dụng xem phim trực tuyến
        
        Phiên bản: \(appVersion) (\(buildNumber))
        
        © 2026 Emmew. All rights reserved.
        
        Phát triển bởi đội ngũ Emmew.
        """
    }
    
    var termsText: String {
        """
        ĐIỀU KHOẢN & ĐIỀU KIỆN
        
        1. Chấp nhận điều khoản
        Bằng việc sử dụng ứng dụng EMCC, bạn đồng ý với các điều khoản này.
        
        2. Nội dung
        Ứng dụng cung cấp nội dung phim từ các nguồn công khai trên internet.
        
        3. Sử dụng cá nhân
        Ứng dụng chỉ dành cho mục đích sử dụng cá nhân, không thương mại.
        
        4. Bản quyền
        Chúng tôi tôn trọng bản quyền. Nếu bạn là chủ sở hữu nội dung, vui lòng liên hệ.
        """
    }
    
    var privacyText: String {
        """
        CHÍNH SÁCH BẢO MẬT
        
        1. Thu thập dữ liệu
        Chúng tôi chỉ lưu email và lịch sử xem của bạn trên thiết bị.
        
        2. Không chia sẻ
        Dữ liệu của bạn không được chia sẻ với bên thứ ba.
        
        3. Bảo mật
        Dữ liệu được lưu cục bộ và bảo vệ bởi hệ thống iOS.
        
        4. Xóa dữ liệu
        Bạn có thể xóa dữ liệu bất kỳ lúc nào trong mục Cài đặt.
        """
    }
}

// MARK: - Info Popup
struct InfoPopupView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { dismiss() }
            
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 10)
                
                ScrollView {
                    Text(content)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }
            .frame(width: 300, maxHeight: 400)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.12)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.5), radius: 20)
        }
    }
}