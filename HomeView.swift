// Hero Banner với avatar đăng nhập
ZStack(alignment: .topTrailing) {
    TabView(selection: $currentIndex) {
        ForEach(Array(vm.trending.prefix(5).enumerated()), id: \.element.id) { i, movie in
            NavigationLink(destination: MovieDetailView(movie: movie)) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: movie.backdropURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.gray.opacity(0.08))
                        }
                    }
                    .frame(height: 450).clipped()
                    
                    LinearGradient(colors: [.clear, .black], startPoint: .center, endPoint: .bottom)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(movie.title)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .frame(maxWidth: 280, alignment: .leading)
                        HStack {
                            Image(systemName: "star.fill").foregroundColor(.white.opacity(0.6)).font(.caption)
                            Text(movie.ratingText).foregroundColor(.white).font(.caption)
                        }
                    }
                    .padding()
                }
            }
            .tag(i)
        }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .frame(height: 450)
    .animation(.easeInOut(duration: 0.4), value: currentIndex)
    
    // Avatar nút đăng nhập góc phải
    NavigationLink(destination: ProfileView()) {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 18))
            )
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
    }
    .padding(.top, 50)
    .padding(.trailing, 20)
}
