import SwiftUI

struct ActorDetailView: View {
    let actor: Actor
    @State private var actorDetail: Actor?
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var showFullBio = false
    @Environment(\.dismiss) var dismiss
    
    private let columns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Blur background từ ảnh diễn viên
            if let url = actor.profileURL {
                CachedAsyncImage(url: url)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .blur(radius: 60)
                    .opacity(0.2)
                    .ignoresSafeArea()
            }
            
            LinearGradient(colors: [Color(white: 0.08).opacity(0.7), Color(white: 0.02).opacity(0.9), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.white)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(spacing: 12) {
                            if let url = actor.profileURL {
                                CachedAsyncImage(url: url)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 130, height: 130)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                                    .shadow(color: .black.opacity(0.5), radius: 10)
                            } else {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 130, height: 130)
                                    .overlay(Image(systemName: "person.fill").foregroundColor(.gray).font(.system(size: 50)))
                                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 2))
                            }
                            
                            Text(actor.name)
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                            
                            if let detail = actorDetail {
                                Text(detail.knownForDepartment ?? "Diễn viên")
                                    .font(.caption).foregroundColor(.gray)
                                    .padding(.horizontal, 12).padding(.vertical, 4)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 90)
                        
                        if let detail = actorDetail {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Thông tin").font(.headline).fontWeight(.bold).foregroundColor(.white)
                                if let bday = detail.birthday {
                                    infoRow(icon: "calendar", title: "Sinh nhật", value: bday)
                                }
                                if let place = detail.placeOfBirth {
                                    infoRow(icon: "mappin.and.ellipse", title: "Nơi sinh", value: place)
                                }
                                infoRow(icon: "theatermasks.fill", title: "Nổi tiếng", value: detail.knownForDepartment ?? "Diễn viên")
                            }
                            .padding(.horizontal)
                            
                            if let bio = detail.biography, !bio.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Tiểu sử").font(.headline).fontWeight(.bold).foregroundColor(.white)
                                    Text(bio)
                                        .font(.caption).foregroundColor(.gray)
                                        .lineLimit(showFullBio ? nil : 4)
                                    if bio.count > 200 {
                                        Button(showFullBio ? "Ẩn bớt" : "Xem thêm") {
                                            withAnimation { showFullBio.toggle() }
                                        }
                                        .font(.caption).foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        if !movies.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Phim tiêu biểu")
                                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                                    Spacer()
                                    if movies.count > 9 {
                                        NavigationLink(destination: ActorMoviesView(actorName: actor.name, movies: movies)) {
                                            HStack(spacing: 4) {
                                                Text("Xem tất cả").font(.caption).foregroundColor(.gray)
                                                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(movies.prefix(9)) { movie in
                                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                                            VStack(spacing: 6) {
                                                if let url = movie.posterURL {
                                                    CachedAsyncImage(url: url)
                                                        .aspectRatio(2/3, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                        .shadow(color: .black.opacity(0.3), radius: 3)
                                                } else {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(.ultraThinMaterial)
                                                        .aspectRatio(2/3, contentMode: .fit)
                                                        .frame(maxWidth: .infinity)
                                                        .overlay(Image(systemName: "film").foregroundColor(.gray).font(.system(size: 24)))
                                                }
                                                Text(movie.title)
                                                    .font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                            }
                                            .scaleEffect(1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: UUID())
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer().frame(height: 50)
                    }
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    )
            }
            .padding(.top, 54)
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .task {
            actorDetail = try? await APIService.shared.actorDetail(actorId: actor.id)
            movies = (try? await APIService.shared.actorMovies(actorId: actor.id)) ?? []
            isLoading = false
        }
    }
    
    @ViewBuilder func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(.gray).frame(width: 20)
            Text(title).font(.caption).foregroundColor(.gray)
            Spacer()
            Text(value).font(.caption).foregroundColor(.white)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ActorMoviesView: View {
    let actorName: String
    let movies: [Movie]
    @Environment(\.dismiss) var dismiss
    
    private let columns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) {
                            VStack(spacing: 6) {
                                if let url = movie.posterURL {
                                    CachedAsyncImage(url: url)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: .black.opacity(0.3), radius: 3)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                        .aspectRatio(2/3, contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                }
                                Text(movie.title)
                                    .font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                    Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 90)
                .padding(.bottom, 100)
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    )
            }
            .padding(.top, 54)
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
    }
}