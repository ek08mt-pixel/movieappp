import SwiftUI

struct NewEpisodeBadge: View {
    let movieId: Int
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.hasNewEpisode(movieId: movieId) {
            Text("TẬP MỚI")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(.yellow))
                .shadow(color: .black.opacity(0.4), radius: 2)
        }
    }
} 