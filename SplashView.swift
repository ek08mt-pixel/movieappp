import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var showMain = false
    @State private var isBlocked = false
    @State private var blockTitle = ""
    @State private var blockMessage = ""
    @State private var buttonText = ""
    @State private var buttonURL = ""
    @State private var isLoading = true
    @State private var rotation: Double = 0
    
    private let configURL = "https://gist.githubusercontent.com/ek08mt-pixel/05d20393f190cd3457a0b9912e87d22d/raw/dbc6fab4d82f0e5326f2cb521b9a65f61815f1fc/emmew_config.json"
    private let currentVersion = "1.0"
    
    let posterNames = ["interstellar", "your_name", "spirited_away", "the_witcher", "lotr", "suzume",
                       "inception", "parasite", "dark_knight", "pulp_fiction", "blade_runner", "dune"]
    
    var body: some View {
        ZStack {
            // Background: poster grid với overlay tối
            GeometryReader { geo in
                ZStack {
                    posterGridView(size: geo.size)
                        .blur(radius: 4)
                    
                    // Vignette nhẹ ở viền, không che mất poster trung tâm
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.75)
                        ]),
                        center: .center,
                        startRadius: geo.size.width * 0.25,
                        endRadius: max(geo.size.width, geo.size.height) * 0.75
                    )
                    
                    // Overlay tổng giảm xuống 0.7 để thấy rõ poster
                    Color.black.opacity(0.7)
                }
            }
            .ignoresSafeArea()
            
            if isLoading {
                // Logo + brand name + slogan (centered)
                VStack(spacing: 10) {
                    // Cat silhouette logo - phóng to 1.5x
                    catLogoView
                    
                    // Brand name - font dày, letter-spacing rộng
                    Text("EMCC")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .tracking(8)
                    
                    // Slogan - viết hoa, không dấu chấm, tracking kéo dài bằng EMCC
                    Text("MEOW & CHILL")
                        .font(.system(size: 11, weight: .light, design: .default))
                        .foregroundColor(Color(red: 0.63, green: 0.63, blue: 0.63))
                        .tracking(6)
                }
            } else if isBlocked {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(blockTitle.isEmpty ? "Oops... hết date mất rùi" : blockTitle)
                        .font(.title2).fontWeight(.bold).foregroundColor(.white).multilineTextAlignment(.center)
                    
                    Text(blockMessage.isEmpty ? "Nhắn @onebraincellcat để lấy file mới " : blockMessage)
                        .font(.body).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                    
                    if !buttonURL.isEmpty {
                        Button {
                            if let url = URL(string: buttonURL) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(buttonText.isEmpty ? "Tải bản mới" : buttonText)
                                .font(.headline).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Capsule().fill(.ultraThinMaterial))
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        }.padding(.horizontal, 50)
                    }
                    
                    Spacer()
                    Text("Emmew © 2026").font(.caption).foregroundColor(.gray.opacity(0.5))
                }
            } else {
                MainTabView().environmentObject(appState)
            }
        }
        .task { await checkConfig() }
    }
    
    // Cat silhouette with glow - 1.5x bigger, sharper lines
    var catLogoView: some View {
        ZStack {
            // Glow effect - to hơn
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 120, height: 120)
                .blur(radius: 25)
            
            // Cat head shape - nét dày hơn, sắc sảo hơn
            catShape
                .stroke(Color.white, lineWidth: 2.0)
                .frame(width: 90, height: 82)
                .shadow(color: .white.opacity(0.7), radius: 10)
        }
    }
    
    var catShape: some Shape {
        CatSilhouette()
    }
    
    // Poster grid - perspective rõ ràng, màu sáng hơn
    func posterGridView(size: CGSize) -> some View {
        let columns = 4
        let rows = 6
        let cellW = size.width / CGFloat(columns) * 1.4
        let cellH = cellW * 1.5
        
        return ZStack {
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { col in
                    let index = (row * columns + col) % posterNames.count
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    posterColor(seed: index),
                                    posterColor(seed: index + 7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                        .frame(width: cellW, height: cellH)
                        .overlay(
                            VStack {
                                // Giả lập poster art với text placeholder
                                Text(posterNames[index].replacingOccurrences(of: "_", with: " ").uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.35))
                                    .tracking(1)
                                    .multilineTextAlignment(.center)
                                    .padding(4)
                                Spacer()
                            }
                        )
                        .rotationEffect(.degrees(-6))
                        .offset(
                            x: CGFloat(col) * cellW * 0.82 - size.width * 0.3,
                            y: CGFloat(row) * cellH * 0.82 - size.height * 0.2
                        )
                }
            }
        }
        .rotationEffect(.degrees(5))
        .rotation3DEffect(.degrees(3), axis: (x: 0.8, y: -0.2, z: 0), perspective: 0.3)
        .scaleEffect(1.25)
    }
    
    // Màu poster sáng hơn, rõ ràng hơn
    func posterColor(seed: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.25, green: 0.18, blue: 0.35),
            Color(red: 0.30, green: 0.22, blue: 0.40),
            Color(red: 0.20, green: 0.28, blue: 0.38),
            Color(red: 0.35, green: 0.20, blue: 0.28),
            Color(red: 0.18, green: 0.30, blue: 0.42),
            Color(red: 0.28, green: 0.24, blue: 0.38),
            Color(red: 0.32, green: 0.26, blue: 0.32),
            Color(red: 0.22, green: 0.32, blue: 0.40),
        ]
        return colors[seed % colors.count]
    }
    
    func checkConfig() async {
        guard let url = URL(string: configURL) else { proceedToApp(); return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let allowed = json["allowed"] as? Bool ?? true
                let latestVersion = json["latestVersion"] as? String ?? "1.0"
                
                await MainActor.run {
                    if !allowed || latestVersion != currentVersion {
                        self.isBlocked = true
                        self.blockTitle = json["blockTitle"] as? String ?? ""
                        self.blockMessage = json["blockMessage"] as? String ?? ""
                        self.buttonText = json["buttonText"] as? String ?? ""
                        self.buttonURL = json["buttonURL"] as? String ?? ""
                        self.isLoading = false
                    } else {
                        proceedToApp()
                    }
                }
            } else {
                await MainActor.run { proceedToApp() }
            }
        } catch {
            await MainActor.run { proceedToApp() }
        }
    }
    
    func proceedToApp() {
        withAnimation(.easeInOut(duration: 1.5)) { showMain = true; isLoading = false }
    }
}

// Custom Cat Silhouette Shape - nét sắc sảo hơn
struct CatSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midX = w / 2
        
        // Left ear - sharp triangle
        path.move(to: CGPoint(x: midX * 0.4, y: h * 0.32))
        path.addLine(to: CGPoint(x: midX * 0.55, y: h * 0.02))
        path.addLine(to: CGPoint(x: midX * 0.88, y: h * 0.26))
        
        // Right ear - sharp triangle
        path.move(to: CGPoint(x: midX * 1.12, y: h * 0.26))
        path.addLine(to: CGPoint(x: midX * 1.45, y: h * 0.02))
        path.addLine(to: CGPoint(x: midX * 1.6, y: h * 0.32))
        
        // Head top curve (between ears)
        path.move(to: CGPoint(x: midX * 0.38, y: h * 0.42))
        path.addCurve(
            to: CGPoint(x: midX * 1.62, y: h * 0.42),
            control1: CGPoint(x: midX * 0.22, y: h * 0.08),
            control2: CGPoint(x: midX * 1.78, y: h * 0.08)
        )
        
        // Bottom jaw curve
        path.addCurve(
            to: CGPoint(x: midX * 0.38, y: h * 0.42),
            control1: CGPoint(x: midX * 1.78, y: h * 0.90),
            control2: CGPoint(x: midX * 0.22, y: h * 0.90)
        )
        
        // Left whiskers - sắc nét
        path.move(to: CGPoint(x: midX * 0.58, y: h * 0.52))
        path.addLine(to: CGPoint(x: midX * 0.08, y: h * 0.46))
        
        path.move(to: CGPoint(x: midX * 0.58, y: h * 0.58))
        path.addLine(to: CGPoint(x: midX * 0.04, y: h * 0.60))
        
        path.move(to: CGPoint(x: midX * 0.56, y: h * 0.64))
        path.addLine(to: CGPoint(x: midX * 0.10, y: h * 0.74))
        
        // Right whiskers - sắc nét
        path.move(to: CGPoint(x: midX * 1.42, y: h * 0.52))
        path.addLine(to: CGPoint(x: midX * 1.92, y: h * 0.46))
        
        path.move(to: CGPoint(x: midX * 1.42, y: h * 0.58))
        path.addLine(to: CGPoint(x: midX * 1.96, y: h * 0.60))
        
        path.move(to: CGPoint(x: midX * 1.44, y: h * 0.64))
        path.addLine(to: CGPoint(x: midX * 1.90, y: h * 0.74))
        
        return path
    }
}