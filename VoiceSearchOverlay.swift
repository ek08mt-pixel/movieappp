import SwiftUI

struct VoiceSearchOverlay: View {
    let text: String
    let audioLevel: CGFloat
    let onCancel: () -> Void
    let onComplete: (String) -> Void
    
    @State private var animateWave = false
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .stroke(Color.white.opacity(0.15 - Double(i) * 0.03), lineWidth: 1)
                            .frame(width: 140 + CGFloat(i) * 60, height: 140 + CGFloat(i) * 60)
                            .scaleEffect(pulse ? 1.08 : 0.95)
                            .opacity(pulse ? 0.4 : 0.15)
                            .animation(.easeInOut(duration: 2 + Double(i) * 0.4).repeatForever(autoreverses: true), value: pulse)
                    }
                    
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(RadialGradient(colors: [.white.opacity(0.25), .white.opacity(0.02)], center: .center, startRadius: 5, endRadius: 90))
                            .frame(width: 60 + CGFloat(audioLevel) * 100, height: 60 + CGFloat(audioLevel) * 100)
                            .blur(radius: 15)
                            .animation(.easeOut(duration: 0.2), value: audioLevel)
                    }
                    
                    Circle()
                        .fill(RadialGradient(colors: [.white.opacity(0.9), .white.opacity(0.3)], center: .center, startRadius: 2, endRadius: 40))
                        .frame(width: 30 + CGFloat(audioLevel) * 50, height: 30 + CGFloat(audioLevel) * 50)
                        .blur(radius: 4)
                        .animation(.easeOut(duration: 0.15), value: audioLevel)
                }
                .frame(width: 320, height: 320)
                .onAppear {
                    pulse = true
                }
                
                VStack(spacing: 12) {
                    Text("Đang nghe...")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(text.isEmpty ? "Hãy nói tên phim" : text)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(text.isEmpty ? .white.opacity(0.3) : .white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .animation(.easeInOut(duration: 0.2), value: text)
                }
                
                Spacer()
                
                Button {
                    onCancel()
                } label: {
                    Text("Hủy")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.3)))
                        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                }
                .padding(.bottom, 60)
            }
        }
    }
}