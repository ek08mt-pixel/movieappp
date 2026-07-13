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
    
    private let configURL = "https://gist.githubusercontent.com/ek08mt-pixel/05d20393f190cd3457a0b9912e87d22d/raw/dbc6fab4d82f0e5326f2cb521b9a65f61815f1fc/emmew_config.json"
    private let currentVersion = "1.0"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
    Text("Emmew")
        .font(.system(size: 42, weight: .bold, design: .serif))
        .foregroundColor(.white)
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
        withAnimation { showMain = true; isLoading = false }
    }
}