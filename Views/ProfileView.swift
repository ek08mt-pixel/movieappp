import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar + Login
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.white)
                            }
                            
                            if appState.isLoggedIn {
                                Text(appState.userName)
                                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                            } else {
                                Button("Đăng nhập") {
                                    showLogin = true
                                }
                                .font(.headline)
                                .foregroundColor(.orange)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Stats
                        HStack(spacing: 0) {
                            StatView(value: "\(appState.watchHistory.count)", title: "Đã xem")
                            Divider().frame(height: 40).background(Color.gray.opacity(0.3))
                            StatView(value: "\(appState.favorites.count)", title: "Yêu thích")
                            Divider().frame(height: 40).background(Color.gray.opacity(0.3))
                            StatView(value: "\(totalWatchTime)h", title: "Thời gian")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )
                        .padding(.horizontal)
                        
                        // Favorites
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Phim yêu thích")
                                .font(.title3).fontWeight(.bold).foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if appState.favorites.isEmpty {
                                Text("Chưa có phim yêu thích")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(appState.favorites) { movie in
                                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                                MovieCard(movie: movie, style: .poster)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationTitle("Chung")
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }
    
    var totalWatchTime: Int {
        appState.watchHistory.count * 2
    }
}

struct StatView: View {
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2).fontWeight(.bold).foregroundColor(.orange)
            Text(title)
                .font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
