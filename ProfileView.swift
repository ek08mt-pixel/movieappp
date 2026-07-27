import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingName = false
    @State private var tempName: String = ""
    @State private var showAuth = false
    @State private var showAchievements = false
    
    // Settings
    @AppStorage("userTheme") private var userTheme: String = "dark"
    @AppStorage("seekSeconds") private var seekSeconds: Double = 10
    @State private var selectedQuality = "FHD"
    @State private var useCellularData = true
    @State private var sleepTimer = "Tắt"
    @State private var lowDataWarning = false
    @State private var showClearCacheAlert = false
    @State private var showInfo = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLanguage = false
    
    private let appVersion = "1.0"
    private let buildNumber = "1"
    private let qualityOptions = ["Tự động", "FHD", "4K", "Cao nhất hỗ trợ"]
    private let sleepTimerOptions = ["Tắt", "15 phút", "30 phút", "45 phút", "60 phút", "90 phút"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Avatar + Tên + Danh hiệu
                        HStack(alignment: .center, spacing: 14) {
                            // Avatar
                            ZStack(alignment: .bottom) {
                                if let data = appState.avatarImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable().aspectRatio(contentMode: .fill)
                                        .frame(width: 68, height: 68)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color(white: 0.25), lineWidth: 2.5))
                                } else {
                                    Image(systemName: appState.selectedAvatar)
                                        .font(.system(size: 34))
                                        .foregroundColor(.white)
                                        .frame(width: 68, height: 68)
                                        .background(Circle().fill(Color(white: 0.15)))
                                        .overlay(Circle().stroke(Color(white: 0.25), lineWidth: 2.5))
                                }
                                
                                // Bút chì trong ô tròn
                                Button {
                                    showImagePicker = true
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 22, height: 22)
                                            .overlay(Circle().stroke(Color(white: 0.3), lineWidth: 0.5))
                                        HStack(spacing: 0) {
                                            Text("✎")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.black)
                                            Text("_")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                                .offset(y: 10)
                            }
                            
                            // Tên + Danh hiệu
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    if isEditingName {
                                        HStack(spacing: 4) {
                                            TextField("Tên", text: $tempName)
                                                .textFieldStyle(.plain)
                                                .foregroundColor(.white)
                                                .font(.system(size: 20, weight: .light))
                                                .frame(width: 130)
                                            Button {
                                                appState.nickname = tempName
                                                appState.save()
                                                isEditingName = false
                                            } label: {
                                                Text("✓")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    } else {
                                        Text(appState.nickname.isEmpty ? "Chưa đặt tên" : appState.nickname)
                                            .font(.system(size: 20, weight: .light))
                                            .foregroundColor(.white)
                                        Button {
                                            tempName = appState.nickname
                                            isEditingName = true
                                        } label: {
                                            Text("✎")
                                                .font(.system(size: 11))
                                                .foregroundColor(.gray.opacity(0.6))
                                        }
                                    }
                                }
                                
                                Button {
                                    AchievementManager.shared.refresh(from: appState)
                                    showAchievements = true
                                } label: {
                                    let rank = AchievementManager.shared.userRankData.currentRank
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(rank.color)
                                            .frame(width: 6, height: 6)
                                        Text(rank.shortName)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text("Lv.\(AchievementManager.shared.userRankData.level)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                        Text("›")
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(.white.opacity(0.06)))
                                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        
                        // MARK: - GIAO DIỆN
                        settingsSection(title: "GIAO DIỆN") {
                            languageRow
                            themeRow
                        }
                        
                        // MARK: - ACCOUNT & ĐĂNG KÝ
                        settingsSection(title: "ACCOUNT & ĐĂNG KÝ") {
                            premiumRow
                            deviceRow
                        }
                        
                        // MARK: - PHÁT LẠI
                        settingsSection(title: "PHÁT LẠI") {
                            seekRow
                            sleepTimerRow
                        }
                        
                        // MARK: - MẠNG VÀ DỮ LIỆU
                        settingsSection(title: "MẠNG VÀ DỮ LIỆU") {
                            qualityRow
                            cellularRow
                            lowDataRow
                            cacheRow
                        }
                        
                        // MARK: - THÔNG TIN
                        settingsSection(title: "THÔNG TIN") {
                            infoRow
                            termsRow
                            privacyRow
                            versionRow
                        }
                        
                        // MARK: - Đăng xuất
                        Button {
                            withAnimation { appState.logout() }
                        } label: {
                            Text("Đăng xuất")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))
                                .padding(.horizontal, 32)
                                .padding(.vertical, 10)
                                .background(Capsule().stroke(Color.red.opacity(0.2), lineWidth: 0.8))
                        }
                        .padding(.top, 8)
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) { ImagePicker(image: $inputImage) }
            .sheet(isPresented: $showAuth) { SmartAuthView { email, password in
                appState.smartLogin(email: email, password: password)
                showAuth = false
            }}
            .sheet(isPresented: $showLanguage) { LanguageSelectionView() }
            .sheet(isPresented: $showInfo) { InfoPopupView(title: "Thông tin ứng dụng", content: infoText) }
            .sheet(isPresented: $showTerms) { InfoPopupView(title: "Điều khoản & Điều kiện", content: termsText) }
            .sheet(isPresented: $showPrivacy) { InfoPopupView(title: "Chính sách bảo mật", content: privacyText) }
            .fullScreenCover(isPresented: $showAchievements) { AchievementView() }
            .alert("Xóa bộ nhớ đệm?", isPresented: $showClearCacheAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) { clearCache() }
            } message: { Text("Tất cả dữ liệu cache sẽ bị xóa.") }
            .onChange(of: inputImage) { img in
                if let img = img, let data = img.jpegData(compressionQuality: 0.7) {
                    appState.avatarImageData = data
                    appState.selectedAvatar = ""
                    appState.save()
                }
            }
        }
        .onAppear {
            AchievementManager.shared.refresh(from: appState)
        }
    }
    
    // MARK: - Settings Section Builder
    func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.25)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 0.5))
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Rows
    var languageRow: some View {
        Button { showLanguage = true } label: {
            rowContent(icon: "🌐", title: "Ngôn ngữ", trailing: LanguageManager.shared.currentLanguage.displayName, showArrow: true)
        }
    }
    
    var themeRow: some View {
        HStack {
            Text("🎨").font(.system(size: 16)).frame(width: 28)
            Text("Theme").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Picker("", selection: $userTheme) {
                Text("Tối").tag("dark")
                Text("Sáng").tag("light")
                Text("Hệ thống").tag("system")
            }
            .pickerStyle(.segmented).frame(width: 170)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    var premiumRow: some View {
        rowContent(icon: "💎", title: "Gói dịch vụ", trailing: "Premium", showArrow: true)
    }
    
    var deviceRow: some View {
        rowContent(icon: "📱", title: "Quản lý thiết bị", trailing: "iPhone này", showArrow: true)
    }
    
    var seekRow: some View {
        HStack {
            Text("⏩").font(.system(size: 14)).frame(width: 28)
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
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    var sleepTimerRow: some View {
        HStack {
            Text("⏰").font(.system(size: 16)).frame(width: 28)
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
            Text("📺").font(.system(size: 16)).frame(width: 28)
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
            Text("📶").font(.system(size: 16)).frame(width: 28)
            Text("Sử dụng mạng di động").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $useCellularData)
                .tint(.green)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
    
    var lowDataRow: some View {
        Button {
            lowDataWarning.toggle()
        } label: {
            rowContent(icon: "⚠️", title: "Cảnh báo dữ liệu thấp", trailing: lowDataWarning ? "Bật" : "Tắt", showArrow: true)
        }
    }
    
    var cacheRow: some View {
        Button { showClearCacheAlert = true } label: {
            HStack {
                Text("🗑").font(.system(size: 16)).frame(width: 28)
                Text("Xóa bộ nhớ đệm").font(.system(size: 15)).foregroundColor(.white)
                Spacer()
                Text(formatCacheSize()).font(.system(size: 13)).foregroundColor(.gray)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
    }
    
    var infoRow: some View {
        Button { showInfo = true } label: {
            rowContent(icon: "ℹ️", title: "Thông tin ứng dụng", trailing: "", showArrow: true)
        }
    }
    
    var termsRow: some View {
        Button { showTerms = true } label: {
            rowContent(icon: "📄", title: "Điều khoản & Điều kiện", trailing: "", showArrow: true)
        }
    }
    
    var privacyRow: some View {
        Button { showPrivacy = true } label: {
            rowContent(icon: "🛡", title: "Chính sách bảo mật", trailing: "", showArrow: true)
        }
    }
    
    var versionRow: some View {
        HStack {
            Text("📲").font(.system(size: 16)).frame(width: 28)
            Text("Phiên bản").font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            Text("EMCC \(appVersion) (\(buildNumber))").font(.system(size: 13)).foregroundColor(.gray)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
    
    func rowContent(icon: String, title: String, trailing: String, showArrow: Bool) -> some View {
        HStack {
            Text(icon).font(.system(size: 16)).frame(width: 28)
            Text(title).font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            if !trailing.isEmpty { Text(trailing).font(.system(size: 13)).foregroundColor(.gray) }
            if showArrow { Text("›").font(.system(size: 14, weight: .light)).foregroundColor(.gray) }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
    
    func formatCacheSize() -> String { "0 KB" }
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        ImageCache.shared.clearCache()
        UserDefaults.standard.removeObject(forKey: "phimapi_stream_cache")
    }
    
    var infoText: String { "EMCC - Ứng dụng xem phim trực tuyến\n\nPhiên bản: \(appVersion) (\(buildNumber))\n\n© 2026 Emmew." }
    var termsText: String { "ĐIỀU KHOẢN & ĐIỀU KIỆN\n\n1. Bằng việc sử dụng EMCC, bạn đồng ý với các điều khoản này.\n2. Ứng dụng cung cấp nội dung từ nguồn công khai.\n3. Chỉ dành cho mục đích cá nhân." }
    var privacyText: String { "CHÍNH SÁCH BẢO MẬT\n\n1. Chúng tôi chỉ lưu email và lịch sử xem trên thiết bị.\n2. Dữ liệu không chia sẻ với bên thứ ba.\n3. Bạn có thể xóa dữ liệu bất kỳ lúc nào." }
}

// Giữ nguyên SmartAuthView và ImagePicker
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