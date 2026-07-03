import SwiftUI

struct ActorDetailView: View {
    let actor: Actor
    @State private var detail: Actor?
    @State private var movies: [Movie] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    AsyncImage(url: actor.profileURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .shadow(color: .orange.opacity(0.3), radius: 10)
                    
                    Text(actor.name)
                        .font(.title).fontWeight(.bold).foregroundColor(.white)
                    
                    if let detail = detail {
                        if let bio = detail.biography, !bio.isEmpty {
                            Text(bio)
                                .foregroundColor(.gray).font(.subheadline).padding(.horizontal)
                        }
                        if let birth = detail.birthday {
                            Text("🎂 \(birth)").foregroundColor(.gray)
                        }
                        if let place = detail.placeOfBirth {
                            Text("📍 \(place)").foregroundColor(.gray)
                        }
                    }
                    
                    if !movies.isEmpty {
                        Text("Phim đã đóng")
                            .font(.title3).fontWeight(.bold).foregroundColor(.white)
                            .padding(.top)
                        
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                MovieRow(movie: movie).padding(.horizontal)
                            }
                            Divider().background(Color.gray.opacity(0.3)).padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
        }
        .task {
            detail = await APIService.shared.actorDetail(actorId: actor.id)
            movies = (try? await APIService.shared.actorMovies(actorId: actor.id)) ?? []
        }
    }
}
