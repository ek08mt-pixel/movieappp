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
                
                // Liquid glass background
                ZStack {
                    // Lớp màu chuyển động
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -80, y: -200)
                        .rotationEffect(.degrees(rotation))
                    
                    Circle()
                        .fill(LinearGradient(colors: [.orange.opacity(0.3), .pink.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: 100, y: 100)
                        .rotationEffect(.degrees(-rotation))
                    
                    Circle()
                        .fill(LinearGradient(colors: [.teal.opacity(0.3), .green.opacity(0.15)], startPoint: .bottomLeading, endPoint: .topTrailing))
                        .frame(width: 280, height: 280)
                        .blur(radius: 55)
                        .offset(x: -50, y: 150)
                        .rotationEffect(.degrees(rotation * 0.7))
                    
                    // Glass overlay
                    Color.black.opacity(0.55)
                }
                .ignoresSafeArea()
                
                // Floating particles
                ZStack {
                    ForEach(0..<12) { i in
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
                            .blur(radius: 1)
                            .offset(
                                x: CGFloat.random(in: -150...150),
                                y: CGFloat.random(in: -300...300)
                            )
                            .opacity(glowOpacity)
                    }
                }
                
                // Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 22) {
                        // Logo in glass card
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.ultraThinMaterial.opacity(0.4))
                                .frame(width: 160, height: 160)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(
                                            LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: .white.opacity(0.1), radius: 20, y: 10)
                            
                            CatLogoView(glowOpacity: glowOpacity)
                                .frame(width: 100, height: 85)
                        }
                        .scaleEffect(scale)
                        .opacity(opacity)
                        
                        Text("EMCC")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(10)
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .shadow(color: .white.opacity(0.3), radius: 10)
                    }
                    
                    Spacer()
                    
                    // Glass footer
                    Text("© 2026 Emmew, Inc. All Rights Reserved.")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.bottom, 40)
                        .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.8)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.6
                }
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

struct CatLogoView: View {
    let glowOpacity: Double
    
    var body: some View {
        ZStack {
            CatPath()
                .stroke(Color.white.opacity(glowOpacity * 1.2), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .blur(radius: 8)
            
            CatPath()
                .stroke(Color.white.opacity(glowOpacity), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .blur(radius: 3)
            
            CatPath()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
        }
    }
}

struct CatPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let centerX = w / 2
        
        path.move(to: CGPoint(x: centerX - 7, y: h * 0.22))
        path.addLine(to: CGPoint(x: centerX - 24, y: h * 0.0))
        path.addLine(to: CGPoint(x: centerX - 3, y: h * 0.30))
        
        path.addCurve(to: CGPoint(x: centerX + 3, y: h * 0.30),
                      control1: CGPoint(x: centerX - 3, y: h * 0.08),
                      control2: CGPoint(x: centerX + 3, y: h * 0.08))
        
        path.addLine(to: CGPoint(x: centerX + 24, y: h * 0.0))
        path.addLine(to: CGPoint(x: centerX + 7, y: h * 0.22))
        
        path.addCurve(to: CGPoint(x: centerX + 20, y: h * 0.62),
                      control1: CGPoint(x: centerX + 16, y: h * 0.32),
                      control2: CGPoint(x: centerX + 23, y: h * 0.47))
        
        path.addCurve(to: CGPoint(x: centerX, y: h * 0.72),
                      control1: CGPoint(x: centerX + 16, y: h * 0.75),
                      control2: CGPoint(x: centerX + 9, y: h * 0.72))
        
        path.addCurve(to: CGPoint(x: centerX - 20, y: h * 0.62),
                      control1: CGPoint(x: centerX - 9, y: h * 0.72),
                      control2: CGPoint(x: centerX - 16, y: h * 0.75))
        
        path.addCurve(to: CGPoint(x: centerX - 7, y: h * 0.22),
                      control1: CGPoint(x: centerX - 23, y: h * 0.47),
                      control2: CGPoint(x: centerX - 16, y: h * 0.32))
        
        path.closeSubpath()
        
        path.move(to: CGPoint(x: centerX - 16, y: h * 0.50))
        path.addLine(to: CGPoint(x: centerX - 36, y: h * 0.43))
        path.move(to: CGPoint(x: centerX - 16, y: h * 0.56))
        path.addLine(to: CGPoint(x: centerX - 36, y: h * 0.56))
        path.move(to: CGPoint(x: centerX + 16, y: h * 0.50))
        path.addLine(to: CGPoint(x: centerX + 36, y: h * 0.43))
        path.move(to: CGPoint(x: centerX + 16, y: h * 0.56))
        path.addLine(to: CGPoint(x: centerX + 36, y: h * 0.56))
        
        return path
    }
}