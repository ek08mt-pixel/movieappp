import SwiftUI

struct ExploreView: View {
    @State private var randomMovie: Movie?
    @State private var showRandom = false
    
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
    
    let staffPicks: [(String, String)] = [
        ("The Godfather", "/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
        ("Pulp Fiction", "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg"),
        ("Fight Club", "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"),
    ]
    
    let editorChoice: [(String, String)] = [
        ("Interstellar", "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
        ("Inception", "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg"),
        ("Parasite", "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"),
    ]
    
    let hiddenGems: [(String, String)] = [
        ("Whiplash", "/7fn624j5lj3xTme2SgiLCeuedmO.jpg"),
        ("Oldboy", "/pWDtjs568ZfOTMbURQBYuT4Qxka.jpg"),
        ("A Silent Voice", "/tD4kGqKj5Ld3GQqL0fJwKjK7Gv.jpg"),
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
                        
                        // Nút Random + Mood + Timeline + Guess
                        HStack(spacing: 12) {
                            ExploreButton(icon: "🎲", title: "Random") {
                                Task {
                                    do {
                                        let movies = try await APIService.shared.popular()
                                        randomMovie = movies.randomElement()
                                        showRandom = true
                                    } catch {}
                                }
                            }
                            
                            NavigationLink(destination: MoodPickerView()) {
                                ExploreButtonView(icon: "🎭", title: "Mood")
                            }
                            
                            NavigationLink(destination: TimelineView()) {
                                ExploreButtonView(icon: "📅", title: "Timeline")
                            }
                            
                            NavigationLink(destination: GuessMovieView()) {
                                ExploreButtonView(icon: "❓", title: "Guess")
                            }
                        }
                        .padding(.horizontal)
                        
                        // Collections
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
                        
                        // Staff Picks
                        Text("Staff Picks")
                            .font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(staffPicks, id: \.0) { title, poster in
                                    VStack(spacing: 5) {
                                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(poster)"))
                                            .frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text(title).font(.system(size: 10)).foregroundColor(.white).frame(width: 120)
                                    }
                                }
                            }.padding(.horizontal)
                        }
                        
                        // Editor's Choice
                        Text("Editor's Choice")
                            .font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(editorChoice, id: \.0) { title, poster in
                                    VStack(spacing: 5) {
                                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(poster)"))
                                            .frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text(title).font(.system(size: 10)).foregroundColor(.white).frame(width: 120)
                                    }
                                }
                            }.padding(.horizontal)
                        }
                        
                        // Hidden Gems
                        Text("Hidden Gems")
                            .font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(hiddenGems, id: \.0) { title, poster in
                                    VStack(spacing: 5) {
                                        CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(poster)"))
                                            .frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text(title).font(.system(size: 10)).foregroundColor(.white).frame(width: 120)
                                    }
                                }
                            }.padding(.horizontal)
                        }
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showRandom) {
            if let movie = randomMovie {
                NavigationStack {
                    MovieDetailView(movie: movie)
                        .overlay(alignment: .topTrailing) {
                            Button { showRandom = false } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30)).foregroundColor(.white).padding()
                            }
                        }
                }
            }
        }
    }
}

struct ExploreButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ExploreButtonView(icon: icon, title: title)
        }
    }
}

struct ExploreButtonView: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(icon).font(.system(size: 28))
            Text(title).font(.system(size: 10)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
    }
}