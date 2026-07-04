import SwiftUI

struct ExploreView: View {
    let collections: [(String, String, String)] = [
        ("Oscar", "oscar", "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg"),
        ("Cannes", "cannes", "/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg"),
        ("IMDb Top", "top rated", "/zfbjgQE1uSd9wiPTX4VzsLi0rGG.jpg"),
        ("Netflix", "netflix original", "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg"),
        ("Ghibli", "studio ghibli", "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg"),
        ("Marvel", "marvel studios", "/or06FN3Dka5tukK1e9sl16pB3iy.jpg"),
        ("DC", "dc films", "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg"),
        ("Pixar", "pixar", "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
        ("Disney", "disney", "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg"),
        ("A24", "a24 films", "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"),
        ("Hàn Quốc", "korean movies", "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"),
        ("Nhật Bản", "japanese anime", "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg"),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Khám phá")
                            .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(collections, id: \.0) { title, query, poster in
                                NavigationLink(destination: MovieListView(title: title, movies: [])) {
                                    ZStack(alignment: .bottomLeading) {
                                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(poster)"))
                                            .frame(height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .blur(radius: 2)
                                            .overlay(Color.black.opacity(0.4))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        
                                        Text(title)
                                            .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                            .padding(8)
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