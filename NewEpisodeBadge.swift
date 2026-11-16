import SwiftUI

struct NewEpisodeBadge: View {
    let movieId: Int
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.hasNewEpisode(movieId: movieId) {
            Text("TẬP MỚI")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white) // Chữ màu trắng cho nổi bật
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    ZStack {
                        // Lớp nền trong suốt giống app
                        Capsule().fill(.ultraThinMaterial.opacity(0.8))
                        // Lớp màu loang loang (giả lập gradient lấy từ poster)
                        Capsule().fill(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.1), .black.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 3) // Làm cho nó loang ra, mờ mờ ảo ảo
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 0.5
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}