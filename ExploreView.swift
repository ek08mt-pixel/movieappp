import SwiftUI

struct ExploreView: View {
    @State private var collections: [ExploreCollection] = [
        ExploreCollection(title: "Oscar Winners", icon: "trophy.fill", query: "oscar"),
        ExploreCollection(title: "Cannes Winners", icon: "sparkles", query: "cannes"),
        ExploreCollection(title: "Top IMDb", icon: "star.fill", query: "top rated"),
        ExploreCollection(title: "Netflix Originals", icon: "play.rectangle.fill", query: "netflix"),
        ExploreCollection(title: "Studio Ghibli", icon: "leaf.fill", query: "ghibli"),
        ExploreCollection(title: "Marvel Studios", icon: "shield.fill", query: "marvel"),
        ExploreCollection(title: "DC Films", icon: "bolt.fill", query: "dc"),
        ExploreCollection(title: "Pixar", icon: "circle.fill", query: "pixar"),
        ExploreCollection(title: "Disney", icon: "moon.stars.fill", query: "disney"),
        ExploreCollection(title: "A24", icon: "a.square.fill", query: "a24"),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Khám phá")
                            .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(collections) { col in
                                NavigationLink(destination: MovieListView(title: col.title, movies: [])) {
                                    VStack(spacing: 8) {
                                        Image(systemName: col.icon)
                                            .font(.system(size: 30))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(height: 60)
                                        
                                        Text(col.title)
                                            .font(.caption).fontWeight(.semibold).foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
        }
    }
}

struct ExploreCollection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let query: String
}