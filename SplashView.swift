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
                        .blur(radius: 3)
                    
                    // Dark overlay + vignette
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.6)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: max(geo.size.width, geo.size.height) * 0.8
                    )
                    
                    Color.black.opacity(0.55)
                }
            }
            .ignoresSafeArea()
            
            if isLoading {
                // Logo + brand name + slogan (centered)
                VStack(spacing: 8) {
                    // Cat silhouette logo with glow
                    catLogoView
                    
                    // Brand name
                    Text("EMCC")
                        .font(.system(size: 40, weight: .medium, design: .default))
                        .foregroundColor(.white)
                        .tracking(6)
                    
                    // Slogan
                    Text("meow & chill .")
                        .font(.system(size: 11, weight: .light, design: .default))
                        .foregroundColor(Color(red: 0.63, green: 0.63, blue: 0.63))
                        .tracking(2)
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
    
    // Cat silhouette with glow
    var catLogoView: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 80, height: 80)
                .blur(radius: 20)
            
            // Cat head shape
            catShape
                .stroke(Color.white, lineWidth: 1.5)
                .frame(width: 60, height: 55)
                .shadow(color: .white.opacity(0.6), radius: 8)
        }
    }
    
    // Simple cat silhouette path
    var catShape: some Shape {
        CatSilhouette()
    }
    
    // Poster grid với góc nghiêng nhẹ
    func posterGridView(size: CGSize) -> some View {
        let columns = 4
        let rows = 6
        let cellW = size.width / CGFloat(columns) * 1.3
        let cellH = cellW * 1.5
        
        return ZStack {
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { col in
                    let index = (row * columns + col) % posterNames.count
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    randomDarkColor(seed: index),
                                    randomDarkColor(seed: index + 7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: cellW, height: cellH)
                        .overlay(
                            Text(posterNames[index].replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.2))
                                .rotationEffect(.degrees(-5))
                        )
                        .rotationEffect(.degrees(-5))
                        .offset(
                            x: CGFloat(col) * cellW * 0.85 - size.width * 0.25,
                            y: CGFloat(row) * cellH * 0.85 - size.height * 0.15
                        )
                }
            }
        }
        .rotationEffect(.degrees(5))
        .scaleEffect(1.2)
    }
    
    func randomDarkColor(seed: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.10, green: 0.08, blue: 0.20),
            Color(red: 0.15, green: 0.10, blue: 0.22),
            Color(red: 0.08, green: 0.12, blue: 0.18),
            Color(red: 0.18, green: 0.08, blue: 0.14),
            Color(red: 0.06, green: 0.14, blue: 0.22),
            Color(red: 0.14, green: 0.10, blue: 0.20),
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

// Custom Cat Silhouette Shape
struct CatSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midX = w / 2
        
        // Ears
        path.move(to: CGPoint(x: midX * 0.45, y: h * 0.3))
        path.addLine(to: CGPoint(x: midX * 0.6, y: h * 0.05))
        path.addLine(to: CGPoint(x: midX * 0.9, y: h * 0.25))
        
        // Right ear
        path.move(to: CGPoint(x: midX * 1.1, y: h * 0.25))
        path.addLine(to: CGPoint(x: midX * 1.4, y: h * 0.05))
        path.addLine(to: CGPoint(x: midX * 1.55, y: h * 0.3))
        
        // Head curve
        path.move(to: CGPoint(x: midX * 0.35, y: h * 0.45))
        path.addCurve(
            to: CGPoint(x: midX * 1.65, y: h * 0.45),
            control1: CGPoint(x: midX * 0.2, y: h * 0.15),
            control2: CGPoint(x: midX * 1.8, y: h * 0.15)
        )
        
        // Bottom curve
        path.addCurve(
            to: CGPoint(x: midX * 0.35, y: h * 0.45),
            control1: CGPoint(x: midX * 1.8, y: h * 0.85),
            control2: CGPoint(x: midX * 0.2, y: h * 0.85)
        )
        
        // Whiskers left
        path.move(to: CGPoint(x: midX * 0.6, y: h * 0.55))
        path.addLine(to: CGPoint(x: midX * 0.15, y: h * 0.5))
        
        path.move(to: CGPoint(x: midX * 0.6, y: h * 0.6))
        path.addLine(to: CGPoint(x: midX * 0.12, y: h * 0.62))
        
        path.move(to: CGPoint(x: midX * 0.58, y: h * 0.65))
        path.addLine(to: CGPoint(x: midX * 0.18, y: h * 0.72))
        
        // Whiskers right
        path.move(to: CGPoint(x: midX * 1.4, y: h * 0.55))
        path.addLine(to: CGPoint(x: midX * 1.85, y: h * 0.5))
        
        path.move(to: CGPoint(x: midX * 1.4, y: h * 0.6))
        path.addLine(to: CGPoint(x: midX * 1.88, y: h * 0.62))
        
        path.move(to: CGPoint(x: midX * 1.42, y: h * 0.65))
        path.addLine(to: CGPoint(x: midX * 1.82, y: h * 0.72))
        
        return path
    }
}