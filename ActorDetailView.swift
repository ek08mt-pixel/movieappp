import SwiftUI

struct ActorDetailView: View {
    let actor: Actor
    @State private var actorDetail: Actor?
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.white)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Avatar + Name
                        VStack(spacing: 12) {
                            CachedAsyncImage(url: actor.profileURL)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                                .shadow(color: .black.opacity(0.5), radius: 10)
                            
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
                        
                        // Tiểu sử
                        if let bio = actorDetail?.biography, !bio.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tiểu sử").font(.headline).fontWeight(.bold).foregroundColor(.white)
                                Text(bio).font(.caption).foregroundColor(.gray).lineLimit(8)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Thông tin
                        if let detail = actorDetail {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Thông tin").font(.headline).fontWeight(.bold).foregroundColor(.white)
                                if let bday = detail.birthday {
                                    infoRow(icon: "calendar", title: "Sinh nhật", value: bday)
                                }
                                if let place = detail.placeOfBirth {
                                    infoRow(icon: "mappin.and.ellipse", title: "Nơi sinh", value: place)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Phim tiêu biểu
                        if !movies.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Phim tiêu biểu").font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(movies.prefix(20)) { movie in
                                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                                VStack(spacing: 6) {
                                                    CachedAsyncImage(url: movie.posterURL)
                                                        .aspectRatio(2/3, contentMode: .fill)
                                                        .frame(width: 110, height: 165)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    Text(movie.title).font(.system(size: 10)).foregroundColor(.white).lineLimit(2).frame(width: 110)
                                                }
                                            }
                                        }
                                    }.padding(.horizontal)
                                }
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