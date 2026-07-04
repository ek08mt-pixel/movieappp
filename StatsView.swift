import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Thống kê của bạn")
                            .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                        
                        // Stats cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(title: "Đã lưu", value: "\(appState.favorites.count)", icon: "bookmark.fill", color: .orange)
                            StatCard(title: "Đã xem", value: "\(appState.watchHistory.count)", icon: "eye.fill", color: .blue)
                            StatCard(title: "Đánh giá", value: "76", icon: "star.fill", color: .yellow)
                            StatCard(title: "Thể loại yêu thích", value: "Sci-Fi", icon: "rocket.fill", color: .purple)
                        }
                        .padding(.horizontal)
                        
                        // Genre bar
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Thể loại bạn xem nhiều nhất")
                                .font(.headline).foregroundColor(.white)
                            
                            GenreBar(genre: "Sci-Fi", percentage: 0.7, color: .purple)
                            GenreBar(genre: "Action", percentage: 0.5, color: .red)
                            GenreBar(genre: "Drama", percentage: 0.4, color: .blue)
                            GenreBar(genre: "Comedy", percentage: 0.3, color: .green)
                            GenreBar(genre: "Horror", percentage: 0.2, color: .orange)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        .padding(.horizontal)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 30)).foregroundColor(color)
            Text(value).font(.title).fontWeight(.bold).foregroundColor(.white)
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
    }
}

struct GenreBar: View {
    let genre: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(genre).foregroundColor(.white).font(.caption)
                Spacer()
                Text("\(Int(percentage * 100))%").foregroundColor(.gray).font(.caption)
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.8))
                    .frame(width: geo.size.width * percentage)
            }
            .frame(height: 8)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)))
        }
    }
}