import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showSplash: Bool
    @State private var isBlocked = false
    @State private var blockTitle = ""
    @State private var blockMessage = ""
    @State private var buttonText = ""
    @State private var buttonURL = ""
    @State private var isLoading = true
    
    // Liquid chrome animation
    @State private var chromePhase: CGFloat = 0
    
    private let configURL = "https://gist.githubusercontent.com/ek08mt-pixel/05d20393f190cd3457a0b9912e87d22d/raw/dbc6fab4d82f0e5326f2cb521b9a65f61815f1fc/emmew_config.json"
    private let currentVersion = "1.0"
    
    var body: some View {
        ZStack {
            // Background đen + loang chrome lỏng
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Chrome loang animation
                GeometryReader { geo in
                    ZStack {
                        // Vết loang 1
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(white: 0.25).opacity(0.6),
                                        Color(white: 0.12).opacity(0.3),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: geo.size.width * 0.5
                                )
                            )
                            .frame(width: geo.size.width * 0.7)
                            .position(
                                x: geo.size.width * 0.2 + sin(chromePhase * 1.3) * 60,
                                y: geo.size.height * 0.3 + cos(chromePhase * 0.9) * 80
                            )
                            .blur(radius: 40)
                        
                        // Vết loang 2
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(white: 0.3).opacity(0.5),
                                        Color(white: 0.15).opacity(0.2),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: geo.size.width * 0.4
                                )
                            )
                            .frame(width: geo.size.width * 0.6)
                            .position(
                                x: geo.size.width * 0.8 + cos(chromePhase * 1.1) * 50,
                                y: geo.size.height * 0.7 + sin(chromePhase * 0.7) * 70
                            )
                            .blur(radius: 50)
                        
                        // Vết loang 3 - sáng hơn
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(white: 0.4).opacity(0.4),
                                        Color(white: 0.2).opacity(0.15),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: geo.size.width * 0.3
                                )
                            )
                            .frame(width: geo.size.width * 0.4)
                            .position(
                                x: geo.size.width * 0.5 + sin(chromePhase * 0.8) * 40,
                                y: geo.size.height * 0.5 + cos(chromePhase * 1.2) * 50
                            )
                            .blur(radius: 35)
                    }
                }
                
                // Lớp noise nhẹ tạo texture kim loại
                Rectangle()
                    .fill(.black.opacity(0.3))
                    .ignoresSafeArea()
            }
            
            if isLoading {
                VStack(spacing: 0) {
                    Spacer()
                    
                    // LIQUID CHROME TEXT
                    Text("EMMEW")
                        .font(.system(size: 48, weight: .black, design: .default))
                        .foregroundColor(.clear)
                        .overlay(
                            ZStack {
                                // Base metal
                                LinearGradient(
                                    colors: [
                                        Color(white: 0.5),
                                        Color(white: 0.75),
                                        Color(white: 0.45),
                                        Color(white: 0.7),
                                        Color(white: 0.4)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .mask(
                                    Text("EMMEW")
                                        .font(.system(size: 48, weight: .black, design: .default))
                                )
                                
                                // Chrome highlight di chuyển
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.1),
                                        .white.opacity(0.8),
                                        .white.opacity(0.1),
                                        .white.opacity(0.6),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: UnitPoint(x: chromePhase, y: 0.3),
endPoint: UnitPoint(x: chromePhase + 0.4, y: 0.7)
                                )
                                .mask(
                                    Text("EMMEW")
                                        .font(.system(size: 48, weight: .black, design: .default))
                                )
                                .blendMode(.plusLighter)
                                
                                // Edge highlight
                                Text("EMMEW")
                                    .font(.system(size: 48, weight: .black, design: .default))
                                    .foregroundColor(.clear)
                                    .overlay(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.5),
                                                .clear,
                                                .white.opacity(0.3),
                                                .clear,
                                                .white.opacity(0.5)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .mask(
                                        Text("EMMEW")
                                            .font(.system(size: 48, weight: .black, design: .default))
                                    )
                                    .blendMode(.overlay)
                            }
                        )
                        .shadow(color: .white.opacity(0.3), radius: 20, y: 0)
                        .shadow(color: .white.opacity(0.15), radius: 40, y: 0)
                    
                    Spacer()
                    
                    Text("© 2026 @Emmew All rights")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.4))
                        .padding(.bottom, 40)
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
                    Text("emew © 2026").font(.caption).foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .task {
            await checkConfig()
            // Chrome animation loop
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                chromePhase = 1.0
            }
        }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
                showSplash = false
            }
        }
    }
}