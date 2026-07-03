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
                    AsyncImage(url: actor.profileURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Circle().fill(Color.gray.opacity(0.1))
                        }
                    }
                    .frame(width: 130, height: 130).clipShape(Circle())
                    
                    Text(actor.name).font(.title).fontWeight(.bold).foregroundColor(.white)
                    
                    if let d = detail {
                        if let bio = d.biography { Text(bio).foregroundColor(.gray).font(.subheadline).padding(.horizontal) }
                        if let birth = d.birthday { Text("🎂 \(birth)").foregroundColor(.gray) }
                        if let place = d.placeOfBirth { Text("📍 \(place)").foregroundColor(.gray) }
                    }
                    
                    if !movies.isEmpty {
                        Text("Phim đã tham gia").font(.title3).fontWeight(.bold).foregroundColor(.white).padding(.top)
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                HStack(spacing: 12) {
                                    AsyncImage(url: movie.posterURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.gray.opacity(0.1))
                                        }
                                    }
                                    .frame(width: 60, height: 90).clipShape(RoundedRectangle(cornerRadius: 8))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(movie.title).foregroundColor(.white).font(.headline)
                                        Text(movie.yearText).foregroundColor(.gray).font(.caption)
                                    }
                                    Spacer()
                                }.padding(.horizontal)
                            }
                        }
                    }
                }.padding(.top)
            }
        }
        .task {
            detail = try? await APIService.shared.actorDetail(actorId: actor.id)
            movies = (try? await APIService.shared.actorMovies(actorId: actor.id)) ?? []
        }
    }
}
