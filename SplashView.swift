import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var glowOpacity: Double = 0.3
    @State private var rotation: Double = 0
    
    var body: some View {
        if isActive {
            MainTabView()
                .transition(.opacity.animation(.easeInOut(duration: 0.8)))
        } else {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 300, height: 300).blur(radius: 60).offset(x: -80, y: -200)
                        .rotationEffect(.degrees(rotation))
                    Circle()
                        .fill(LinearGradient(colors: [.orange.opacity(0.3), .pink.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 250, height: 250).blur(radius: 50).offset(x: 100, y: 100)
                        .rotationEffect(.degrees(-rotation))
                    Circle()
                        .fill(LinearGradient(colors: [.teal.opacity(0.3), .green.opacity(0.15)], startPoint: .bottomLeading, endPoint: .topTrailing))
                        .frame(width: 280, height: 280).blur(radius: 55).offset(x: -50, y: 150)
                        .rotationEffect(.degrees(rotation * 0.7))
                    Color.black.opacity(0.55)
                }.ignoresSafeArea()
                
                ForEach(0..<12) { i in
                    Circle().fill(.white.opacity(0.15))
                        .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
                        .blur(radius: 1)
                        .offset(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -300...300))
                        .opacity(glowOpacity)
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 22) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.ultraThinMaterial.opacity(0.4))
                                .frame(width: 160, height: 160)
                                .overlay(RoundedRectangle(cornerRadius: 32).stroke(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                                .shadow(color: .white.opacity(0.1), radius: 20, y: 10)
                            
                            // Play button icon
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 70, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .white.opacity(0.5), radius: 10)
                        }
                        .scaleEffect(scale).opacity(opacity)
                        
                        Text("EMCC")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white).tracking(10)
                            .scaleEffect(scale).opacity(opacity)
                            .shadow(color: .white.opacity(0.3), radius: 10)
                    }
                    Spacer()
                    Text("© 2026 Emmew, Inc. All Rights Reserved.")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.25)).padding(.bottom, 40).opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.8)) { scale = 1.0; opacity = 1.0 }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { glowOpacity = 0.6 }
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { rotation = 360 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.8)) { isActive = true }
                }
            }
        }
    }
}