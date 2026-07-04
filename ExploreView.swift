import SwiftUI

struct ExploreView: View {
    @State private var collections: [(String, String, String)] = [
        ("Oscar Winners", "trophy.fill", "oscar winners"),
        ("Cannes", "sparkles", "cannes festival"),
        ("Top IMDb", "star.fill", "top imdb"),
        ("Netflix", "play.rectangle.fill", "netflix original"),
        ("Ghibli", "leaf.fill", "studio ghibli"),
        ("Marvel", "shield.fill", "marvel studios"),
        ("DC", "bolt.fill", "dc films"),
        ("Pixar", "circle.fill", "pixar"),
        ("Disney", "moon.stars.fill", "disney"),
        ("A24", "film.fill", "a24 films"),
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
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(collections, id: \.0) { title, icon, query in
                                NavigationLink(destination: MovieListView(title: title, movies: [])) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial)
                                                .frame(height: 70)
                                            
                                            Image(systemName: icon)
                                                .font(.system(size: 28))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        Text(title)
                                            .font(.caption).fontWeight(.semibold).foregroundColor(.white)
                                            .lineLimit(1)
                                    }
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