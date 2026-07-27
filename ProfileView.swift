import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @State private var showAuth = false
    @State private var showAchievements = false
    
    // Settings - lưu thật
    @AppStorage("userTheme") private var userTheme: String = "dark"
    @AppStorage("seekSeconds") private var seekSeconds: Double = 10
    @AppStorage("selectedQuality") private var selectedQuality = "FHD"
    @AppStorage("useCellularData") private var useCellularData = true
    @AppStorage("sleepTimer") private var sleepTimer = "Tắt"
    @AppStorage("lowDataWarning") private var lowDataWarning = false
    @State private var showClearCacheAlert = false
    @State private var showLanguage = false
    
    // Popups nhỏ
    @State private var activePopup: PopupType? = nil
    
    enum PopupType: Identifiable {
        case info, terms, privacy, premium, device
        var id: Int { hashValue }
    }
    
    private let appVersion = "1.0"
    private let buildNumber = "1"
    private let qualityOptions = ["Tự động", "FHD", "4K", "Cao nhất hỗ trợ"]
    private let sleepTimerOptions = ["Tắt", "15 phút", "30 phút", "45 phút", "60 phút", "90 phút"]
    
    // Device info
    private var deviceName: String { UIDevice.current.name }
    private var deviceModel: String { UIDevice.current.model }
    private var systemVersion: String { UIDevice.current.systemVersion }
    private var freeSpace: String {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let free = attrs[.systemFreeSize] as? Int64 {
            return ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
        }
        return "N/A"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Avatar + Tên + Danh hiệu
                        VStack(spacing: 14) {
                            // Avatar
                            ZStack(alignment: .bottom) {
                                if let data = appState.avatarImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable().aspectRatio(contentMode: .fill)
                                        .frame(width: 72, height: 72)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color(white: 0.25), lineWidth: 2.5))
                                } else {
                                    Image(systemName: appState.selectedAvatar)
                                        .font(.system(size: 34))
                                        .foregroundColor(.white)
                                        .frame(width: 72, height: 72)
                                        .background(Circle().fill(Color(white: 0.15)))
                                        .overlay(Circle().stroke(Color(white: 0.25), lineWidth: 2.5))
                                }
                                
                                Button {
                                    showImagePicker = true
                                } label: {
                                    ZStack {
                                        Circle().fill(.white).frame(width: 22, height: 22)
                                        HStack(spacing: 0) {
                                            Text("✎").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                                            Text("_").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                                        }
                                    }
                                }
                                .offset(y: 10)
                            }
                            
                            // Tên
                            HStack(spacing: 6) {
                                if isEditingName {
                                    HStack(spacing: 4) {
                                        TextField("Tên", text: $tempName)
                                            .textFieldStyle(.plain).foregroundColor(.white)
                                            .font(.system(size: 20, weight: .light)).multilineTextAlignment(.center)
                                            .frame(width: 140)
                                        Button {
                                            appState.nickname = tempName; appState.save(); isEditingName = false
                                        } label: {
                                            Text("✓").font(.system(size: 13, weight: .bold)).foregroundColor(.green)
                                        }
                                    }
                                } else {
                                    Text(appState.nickname.isEmpty ? "Chưa đặt tên" : appState.nickname)
                                        .font(.system(size: 20, weight: .light)).foregroundColor(.white)
                                    Button {
                                        tempName = appState.nickname; isEditingName = true
                                    } label: {
                                        Image(systemName: "pencil").font(.system(size: 10)).foregroundColor(.gray.opacity(0.6))
                                    }
                                }
                            }
                            
                            // Danh hiệu - căn giữa
                            Button {
                                AchievementManager.shared.refresh(from: appState)
                                showAchievements = true
                            } label: {
                                let rank = AchievementManager.shared.userRankData.currentRank
                                HStack(spacing: 5) {
                                    Circle().fill(rank.color).frame(width: 7, height: 7)
                                    Text(rank.shortName)
                                        .font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.85))
                                    Text("Lv.\(AchievementManager.shared.userRankData.level)")
                                        .font(.system(size: 11)).foregroundColor(.gray)
                                    Image(systemName: "chevron.right").font(.system(size: 8)).foregroundColor(.gray)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(Capsule().fill(.white.opacity(0.06)))
                                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                            }
                        }
                        .padding(.top, 60)
                        
                        // MARK: - GIAO DIỆN
                        settingsSection(title: "GIAO DIỆN") {
                            Button { showLanguage = true } label: {
                                settingRow(icon: "globe", title: "Ngôn ngữ", trailing: LanguageManager.shared.currentLanguage.displayName)
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            themeRow
                        }
                        
                        // MARK: - ACCOUNT
                        settingsSection(title: "ACCOUNT & ĐĂNG KÝ") {
                            Button { activePopup = .premium } label: {
                                settingRow(icon: "crown.fill", title: "Gói dịch vụ", trailing: "Premium", iconColor: .yellow)
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            Button { activePopup = .device } label: {
                                settingRow(icon: "iphone.gen3", title: "Quản lý thiết bị", trailing: deviceName)
                            }
                        }
                        
                        // MARK: - PHÁT LẠI
                        settingsSection(title: "PHÁT LẠI") {
                            seekRow
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            sleepTimerRow
                        }
                        
                        // MARK: - MẠNG VÀ DỮ LIỆU
                        settingsSection(title: "MẠNG VÀ DỮ LIỆU") {
                            qualityRow
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            cellularRow
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            lowDataRow
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            Button { showClearCacheAlert = true } label: {
                                HStack {
                                    Image(systemName: "trash.fill").font(.system(size: 14)).foregroundColor(.red.opacity(0.7)).frame(width: 28)
                                    Text("Xóa bộ nhớ đệm").font(.system(size: 15)).foregroundColor(.white)
                                    Spacer()
                                    Text(formatCacheSize()).font(.system(size: 13)).foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                            }
                        }
                        
                        // MARK: - THÔNG TIN
                        settingsSection(title: "THÔNG TIN") {
                            Button { activePopup = .info } label: { settingRow(icon: "info.circle", title: "Thông tin ứng dụng") }
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            Button { activePopup = .terms } label: { settingRow(icon: "doc.text", title: "Điều khoản & Điều kiện") }
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            Button { activePopup = .privacy } label: { settingRow(icon: "hand.raised", title: "Chính sách bảo mật") }
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            HStack {
                                Image(systemName: "apps.iphone").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
                                Text("Phiên bản").font(.system(size: 15)).foregroundColor(.white)
                                Spacer()
                                Text("EMCC \(appVersion) (\(buildNumber))").font(.system(size: 13)).foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                        }
                        
                        // MARK: - Đăng xuất
                        Button {
                            withAnimation { appState.logout() }
                        } label: {
                            Text("Đăng xuất")
                                .font(.system(size: 13, weight: .medium)).foregroundColor(.red.opacity(0.7))
                                .padding(.horizontal, 32).padding(.vertical, 10)
                                .background(Capsule().stroke(Color.red.opacity(0.2), lineWidth: 0.8))
                        }
                        .padding(.top, 8)
                        
                        Spacer().frame(height: 120)
                    }
                }
                
                // Popup nhỏ
                if activePopup != nil {
                    Color.black.opacity(0.5).ignoresSafeArea()
                        .onTapGesture { activePopup = nil }
                        .zIndex(1)
                    
                    popupContent
                        .zIndex(2)
                }
            }
            .sheet(isPresented: $showImagePicker) { ImagePicker(image: $inputImage) }
            .sheet(isPresented: $showAuth) { SmartAuthView { email, password in
                appState.smartLogin(email: email, password: password); showAuth = false
            }}
            .sheet(isPresented: $showLanguage) { LanguageSelectionView() }
            .fullScreenCover(isPresented: $showAchievements) { AchievementView() }
            .alert("Xóa bộ nhớ đệm?", isPresented: $showClearCacheAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) { clearCache() }
            } message: { Text("Tất cả dữ liệu cache sẽ bị xóa.") }
            .onChange(of: inputImage) { img in
                if let img = img, let data = img.jpegData(compressionQuality: 0.7) {
                    appState.avatarImageData = data; appState.selectedAvatar = ""; appState.save()
                }
            }
        }
        .onAppear { AchievementManager.shared.refresh(from: appState) }
    }
    
    // MARK: - Popup Content
    @ViewBuilder
    var popupContent: some View {
        switch activePopup {
        case .info:
            popupCard(title: "Thông tin", content: infoText)
        case .terms:
            popupCard(title: "Điều khoản", content: termsText)
        case .privacy:
            popupCard(title: "Bảo mật", content: privacyText)
        case .premium:
            VStack(spacing: 16) {
                Image(systemName: "crown.fill").font(.system(size: 40)).foregroundColor(.yellow)
                Text("Premium").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("Tính năng đang được phát triển.\nHãy quay lại sau nhé!")
                    .font(.system(size: 13)).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            .padding(24).frame(width: 260)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.12)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 0.5))
        case .device:
            VStack(spacing: 14) {
                Image(systemName: "iphone.gen3").font(.system(size: 36)).foregroundColor(.white.opacity(0.7))
                Text("Thiết bị của bạn").font(.headline).foregroundColor(.white)
                VStack(spacing: 6) {
                    deviceInfoRow(label: "Tên máy", value: deviceName)
                    deviceInfoRow(label: "Model", value: deviceModel)
                    deviceInfoRow(label: "iOS", value: systemVersion)
                    deviceInfoRow(label: "Dung lượng trống", value: freeSpace)
                }
            }
            .padding(24).frame(width: 280)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.12)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 0.5))
        case nil:
            EmptyView()
        }
    }
    
    func popupCard(title: String, content: String) -> some View {
        VStack(spacing: 10) {
            Text(title).font(.headline).foregroundColor(.white)
            ScrollView { Text(content).font(.system(size: 12)).foregroundColor(.white.opacity(0.8)) }
                .frame(maxHeight: 200)
        }
        .padding(20).frame(width: 280)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.12)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 0.5))
    }
    
    func deviceInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(.gray)
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium)).foregroundColor(.white)
        }
    }
    
    // MARK: - Settings Helpers
    func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.4)).tracking(2)
                .padding(.horizontal, 20)
            VStack(spacing: 0) { content() }
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.25)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 0.5))
                .padding(.horizontal, 20)
        }
    }
    
    func settingRow(icon: String, title: String, trailing: String = "", iconColor: Color = .white.opacity(0.6)) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(iconColor).frame(width: 28)
            Text(title).font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            if !trailing.isEmpty { Text(trailing).font(.system(size: 13)).foregroundColor(.gray) }
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(.gray)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
    
    var themeRow: some View {
        HStack {
            Image(systemName: "circle.lefthalf.filled").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
            Text("Theme").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Picker("", selection: $userTheme) {
                Text("Tối").tag("dark"); Text("Sáng").tag("light"); Text("Hệ thống").tag("system")
            }
            .pickerStyle(.segmented).frame(width: 170)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    var seekRow: some View {
        HStack {
            Image(systemName: "forward.fill").font(.system(size: 14)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
            Text("Thời lượng tua").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Picker("", selection: $seekSeconds) {
                Text("5s").tag(5.0); Text("10s").tag(10.0); Text("15s").tag(15.0)
                Text("20s").tag(20.0); Text("25s").tag(25.0); Text("30s").tag(30.0)
            }
            .pickerStyle(.menu).tint(.white)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    var sleepTimerRow: some View {
        HStack {
            Image(systemName: "timer").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
            Text("Hẹn giờ tắt máy").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Picker("", selection: $sleepTimer) {
                ForEach(sleepTimerOptions, id: \.self) { t in Text(t).tag(t) }
            }
            .pickerStyle(.menu).tint(.white)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    var qualityRow: some View {
        HStack {
            Image(systemName: "tv").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
            Text("Chất lượng video").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Picker("", selection: $selectedQuality) {
                ForEach(qualityOptions, id: \.self) { q in Text(q).tag(q) }
            }
            .pickerStyle(.menu).tint(.white)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    var cellularRow: some View {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
            Text("Sử dụng mạng di động").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $useCellularData)
    .toggleStyle(SwitchToggleStyle(tint: .clear))
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
    )
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    var lowDataRow: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).frame(width: 28)
            Text("Cảnh báo dữ liệu thấp").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $lowDataWarning)
    .toggleStyle(SwitchToggleStyle(tint: .clear))
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
    )
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    func formatCacheSize() -> String { "0 KB" }
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        ImageCache.shared.clearCache()
        UserDefaults.standard.removeObject(forKey: "phimapi_stream_cache")
    }
    
    var infoText: String { "EMCC - Ứng dụng xem phim trực tuyến\n\nPhiên bản: \(appVersion) (\(buildNumber))\n\n© 2026 Emmew." }
    var termsText: String { "ĐIỀU KHOẢN\n\n1. Bằng việc sử dụng EMCC, bạn đồng ý với điều khoản.\n2. Nội dung từ nguồn công khai.\n3. Chỉ dành cho cá nhân." }
    var privacyText: String { "BẢO MẬT\n\n1. Chỉ lưu email và lịch sử xem.\n2. Không chia sẻ dữ liệu.\n3. Có thể xóa bất kỳ lúc nào." }
}

// SmartAuthView + ImagePicker giữ nguyên
// MARK: - SmartAuthView
struct SmartAuthView: View {
    @State private var email = ""; @State private var password = ""; @State private var errorMsg = ""
    let onAuth: (String, String) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack { Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Đăng nhập").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("Nhập email và mật khẩu.\nNếu chưa có tài khoản, hệ thống sẽ tự tạo mới.")
                    .font(.caption).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 30)
                TextField("Email", text: $email).textFieldStyle(.plain).foregroundColor(.white)
                    .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                    .padding(.horizontal, 30).keyboardType(.emailAddress).autocapitalization(.none)
                SecureField("Mật khẩu", text: $password).textFieldStyle(.plain).foregroundColor(.white)
                    .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)).padding(.horizontal, 30)
                if !errorMsg.isEmpty { Text(errorMsg).font(.caption).foregroundColor(.red) }
                Button {
                    guard email.contains("@"), email.contains("."), password.count >= 4 else {
                        errorMsg = "Email hoặc mật khẩu không hợp lệ"; return
                    }
                    onAuth(email, password)
                } label: {
                    Text("Tiếp tục").font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                }.padding(.horizontal, 30)
                Button("Đóng") { dismiss() }.foregroundColor(.gray)
            }
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?; @Environment(\.dismiss) var dismiss
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