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
    @AppStorage("sleepTimer") private var sleepTimer = "Tắt"
    @State private var showClearCacheAlert = false
    @State private var showLanguage = false
    
    // Popups nhỏ
    @State private var activePopup: PopupType? = nil
    
    enum PopupType: Identifiable {
        case info, terms, privacy, device
        var id: Int { hashValue }
    }
    
    private let appVersion = "1.0"
    private let buildNumber = "1"
    private let sleepTimerOptions = ["Tắt", "15 phút", "30 phút", "45 phút", "60 phút", "90 phút"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Avatar + Tên
                        VStack(spacing: 14) {
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
                        }
                        .padding(.top, 60)
                        
                        // MARK: - THỐNG KÊ
                        VStack(spacing: 12) {
                            // 4 ô thống kê - 2 hàng
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                statsCard(value: formatWatchTime(), label: "Thời gian xem", trend: "+\(trendPercent())%")
                                statsCard(value: "\(appState.watchHistory.count)", label: "Phim đã xem")
                                statsCard(value: "\(totalEpisodesWatched())", label: "Tập đã xem")
                                statsCard(value: "\(streakDays())", label: "Ngày liên tiếp")
                            }
                            .padding(.horizontal, 20)
                            
                            // Thể loại yêu thích
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Thể loại yêu thích")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 20) {
                                    // Vòng tròn thống kê
                                    ZStack {
                                        Circle()
                                            .stroke(.white.opacity(0.1), lineWidth: 6)
                                            .frame(width: 70, height: 70)
                                        Circle()
                                            .trim(from: 0, to: topGenrePercent())
                                            .stroke(Color(hex: "#FF6B6B") ?? .red, lineWidth: 6)
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 70, height: 70)
                                        VStack(spacing: 0) {
                                            Text("\(Int(topGenrePercent() * 100))%")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                            Text(topGenreName())
                                                .font(.system(size: 9))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(genreStats().prefix(3), id: \.name) { stat in
                                            HStack(spacing: 6) {
                                                Circle().fill(stat.color).frame(width: 6, height: 6)
                                                Text(stat.name)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.white.opacity(0.7))
                                                Spacer()
                                                Text("\(Int(stat.percent * 100))%")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.25)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 0.5))
                            .padding(.horizontal, 20)
                        }
                        
                        // MARK: - GIAO DIỆN
                        settingsSection(title: "GIAO DIỆN") {
                            Button { showLanguage = true } label: {
                                settingRow(icon: "globe", title: "Ngôn ngữ", trailing: LanguageManager.shared.currentLanguage.displayName)
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            themeRow
                        }
                        
                        // MARK: - PHÁT LẠI
                        settingsSection(title: "PHÁT LẠI") {
                            seekRow
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 44)
                            sleepTimerRow
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
                
                if activePopup != nil {
                    Color.black.opacity(0.5).ignoresSafeArea()
                        .onTapGesture { activePopup = nil }
                        .zIndex(1)
                    popupContent
                        .zIndex(2)
                }
            }
            .sheet(isPresented: $showImagePicker) { ImagePicker(image: $inputImage) }
            .sheet(isPresented: $showLanguage) { LanguageSelectionView() }
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
    }
    
    // MARK: - Stats Functions
    func statsCard(value: String, label: String, trend: String = "") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if !trend.isEmpty {
                Text(trend)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.green)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.25)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.06), lineWidth: 0.5))
    }
    
    func formatWatchTime() -> String {
        let totalSeconds = appState.watchProgressList.reduce(0) { $0 + $1.currentTime }
        let hours = totalSeconds / 3600
        if hours >= 1 {
            return String(format: "%.1f giờ", hours)
        }
        let minutes = totalSeconds / 60
        return "\(Int(minutes)) phút"
    }
    
    func trendPercent() -> Int {
        let total = appState.watchProgressList.reduce(0) { $0 + $1.currentTime }
        return max(1, Int(total / 60)) // % tăng so với tháng trước (đơn giản hóa)
    }
    
    func totalEpisodesWatched() -> Int {
        appState.watchProgressList.filter { $0.episode != nil }.count
    }
    
    func streakDays() -> Int {
        let dates = appState.watchHistory.compactMap { $0.releaseDate?.prefix(4) }
        return max(1, Set(dates).count) // Đơn giản hóa - đếm ngày khác nhau
    }
    
    func genreStats() -> [(name: String, percent: Double, color: Color)] {
        var genreCount: [String: Int] = [:]
        for movie in appState.watchHistory {
            if let genres = movie.genreIds {
                for g in genres {
                    let name = genreName(g)
                    genreCount[name, default: 0] += 1
                }
            }
        }
        let total = max(genreCount.values.reduce(0, +), 1)
        let colors: [Color] = [Color(hex: "#FF6B6B") ?? .red, Color(hex: "#4D96FF") ?? .blue, Color(hex: "#6BCB77") ?? .green]
        return genreCount.sorted { $0.value > $1.value }.prefix(3).enumerated().map { index, item in
            (name: item.key, percent: Double(item.value) / Double(total), color: colors[index % colors.count])
        }
    }
    
    func topGenreName() -> String {
        genreStats().first?.name ?? "Chưa có"
    }
    
    func topGenrePercent() -> Double {
        genreStats().first?.percent ?? 0
    }
    
    func genreName(_ id: Int) -> String {
        let map: [Int: String] = [
            28: "Hành động", 12: "Phiêu lưu", 16: "Hoạt hình", 35: "Hài",
            80: "Hình sự", 99: "Tài liệu", 18: "Chính kịch", 10751: "Gia đình",
            14: "Giả tưởng", 36: "Lịch sử", 27: "Kinh dị", 10402: "Âm nhạc",
            9648: "Bí ẩn", 10749: "Lãng mạn", 878: "Khoa học viễn tưởng", 10770: "TV Movie",
            53: "Gây cấn", 10752: "Chiến tranh", 37: "Miền Tây"
        ]
        return map[id] ?? "Khác"
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
        case .device:
            VStack(spacing: 14) {
                Image(systemName: "iphone.gen3").font(.system(size: 36)).foregroundColor(.white.opacity(0.7))
                Text("Thiết bị của bạn").font(.headline).foregroundColor(.white)
                VStack(spacing: 6) {
                    deviceInfoRow(label: "Tên máy", value: UIDevice.current.name)
                    deviceInfoRow(label: "Model", value: UIDevice.current.model)
                    deviceInfoRow(label: "iOS", value: UIDevice.current.systemVersion)
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