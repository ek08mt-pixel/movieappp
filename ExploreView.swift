import SwiftUI

// MARK: - Explore View
struct ExploreView: View {
    @State private var randomMovie: Movie?; @State private var showRandom = false
    @State private var staffMovies: [Movie] = []; @State private var editorMovies: [Movie] = []; @State private var hiddenMovies: [Movie] = []
    
    let collections: [(String, Int, CategoryConfig.CategoryType)] = [
        ("Oscar", 2959, .keyword), ("Cannes", 133278, .keyword), ("IMDb Top", 210024, .keyword),
        ("Netflix", 213, .studio), ("Ghibli", 103538, .studio), ("Marvel", 420, .studio),
        ("DC", 429, .studio), ("Pixar", 3, .studio), ("Disney", 2, .studio), ("A24", 135334, .studio)
    ]
    
    let posterMap: [String: String] = [
        "Oscar": "/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg", "Cannes": "/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg",
        "IMDb Top": "/zfbjgQE1uSd9wiPTX4VzsLi0rGG.jpg", "Netflix": "/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg",
        "Ghibli": "/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg", "Marvel": "/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
        "DC": "/nMKdUUepR0i5zn0y1T4CsSB5ecy.jpg", "Pixar": "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
        "Disney": "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg", "A24": "/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(white: 0.12), Color(white: 0.05), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Khám phá").font(.largeTitle).fontWeight(.bold).foregroundColor(.white).padding(.top, 8).padding(.horizontal, 16)
                        
                        HStack(spacing: 10) {
                            NavigationLink(destination: OSTView()) {
                                VStack(spacing: 6) { Text("🎵").font(.system(size: 26)); Text("OST").font(.system(size: 10)).foregroundColor(.white) }.frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: FilmHubView()) {
                                VStack(spacing: 6) { Text("🎬").font(.system(size: 26)); Text("Góc phim").font(.system(size: 10)).foregroundColor(.white) }.frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: TimelineView()) {
                                VStack(spacing: 6) { Text("📅").font(.system(size: 26)); Text("Timeline").font(.system(size: 10)).foregroundColor(.white) }.frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                            NavigationLink(destination: GuessMovieView()) {
                                VStack(spacing: 6) { Text("❓").font(.system(size: 26)); Text("Guess").font(.system(size: 10)).foregroundColor(.white) }.frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                            }
                        }.padding(.horizontal, 16)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(collections, id: \.0) { title, tmdbId, type in
                                NavigationLink(destination: CategoryFullView(category: CategoryConfig(id: 0, name: title, posterName: "", type: type, tmdbId: tmdbId))) {
                                    ZStack(alignment: .bottomLeading) {
                                        RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 100)
                                        if let p = posterMap[title], let url = URL(string: "https://image.tmdb.org/t/p/w500\(p)") { CachedAsyncImage(url: url).aspectRatio(contentMode: .fill).frame(height: 100).clipShape(RoundedRectangle(cornerRadius: 14)) }
                                        LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom).clipShape(RoundedRectangle(cornerRadius: 14))
                                        Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                    }.frame(height: 100)
                                }
                            }
                        }.padding(.horizontal, 16)
                        
                        if !staffMovies.isEmpty { movieRow(title: "Staff Picks", movies: staffMovies) }
                        if !editorMovies.isEmpty { movieRow(title: "Editor's Choice", movies: editorMovies) }
                        if !hiddenMovies.isEmpty { movieRow(title: "Hidden Gems", movies: hiddenMovies) }
                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        .task { loadData() }
    }
    
    func loadData() {
        Task {
            staffMovies = (try? await APIService.shared.topRated())?.filter { !($0.adult ?? false) } ?? []
            editorMovies = (try? await APIService.shared.discoverMovies(minRating: 8.0, minVotes: 1000))?.filter { !($0.adult ?? false) } ?? []
            hiddenMovies = (try? await APIService.shared.discoverMovies(minRating: 7.0, minVotes: 30))?.filter { !($0.adult ?? false) } ?? []
        }
    }
    
    @ViewBuilder func movieRow(title: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) { ForEach(movies.prefix(20)) { m in NavigationLink(destination: MovieDetailView(movie: m)) { CachedAsyncImage(url: m.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 110, height: 165).clipShape(RoundedRectangle(cornerRadius: 10)) } } }.padding(.horizontal)
            }
        }
    }
}

// MARK: - FilmHubView
struct FilmHubView: View {
    @Environment(\.dismiss) var dismiss
    let hubItems: [(String, String, Color)] = [
        ("Diễn viên hot", "Ngôi sao được yêu thích", .orange),
        ("Đạo diễn tài ba", "Nhà làm phim xuất sắc", .purple),
        ("Ngày này năm xưa", "Phim công chiếu hôm nay", .blue),
        ("Cặp bài trùng", "Bạn diễn ăn ý nhất", .pink),
        ("Quote huyền thoại", "Câu thoại bất hủ", .teal),
        ("So sánh phim", "Đối đầu điện ảnh", .green),
        ("Top doanh thu", "Phòng vé toàn cầu", .red),
        ("Vũ trụ điện ảnh", "MCU, DC, Star Wars...", .indigo)
    ]
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    Text("Góc phim").font(.largeTitle).fontWeight(.bold).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(hubItems, id: \.0) { title, subtitle, color in
                            NavigationLink(destination: hubDestination(for: title)) {
                                VStack(spacing: 8) {
                                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                    Text(subtitle).font(.system(size: 11)).foregroundColor(.gray).lineLimit(1)
                                }.frame(maxWidth: .infinity).padding(.vertical, 28)
                                .background(RoundedRectangle(cornerRadius: 16).fill(color.opacity(0.15)))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.2), lineWidth: 0.5))
                            }
                        }
                    }.padding(.horizontal, 16)
                    Spacer().frame(height: 120)
                }
            }
            backButton
        }.navigationBarHidden(true)
    }
    
    var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5)))
        }.padding(.top, 54).padding(.leading, 16)
    }
    
    @ViewBuilder
    func hubDestination(for t: String) -> some View {
        switch t {
        case "Diễn viên hot": ActorHotView()
        case "Đạo diễn tài ba": DirectorView(directorName: "Christopher Nolan")
        case "Ngày này năm xưa": ThisDayHistoryView()
        case "Cặp bài trùng": PairView()
        case "Quote huyền thoại": QuoteView(movieId: 550)
        case "So sánh phim": CompareView()
        case "Top doanh thu": CategoryFullView(category: CategoryConfig(id: 0, name: "Doanh thu", posterName: "", type: .keyword, tmdbId: 210024))
        case "Vũ trụ điện ảnh": UniverseView()
        default: Color.black
        }
    }
}

// MARK: - Actor Hot View
struct ActorHotView: View {
    @Environment(\.dismiss) var dismiss
    @State private var actors: [Actor] = []
    @State private var searchText = ""
    @State private var selectedActor: Actor?
    
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    // Data fake ban đầu
    let fakeActors: [Actor] = [
        Actor(id: 6193, name: "Leonardo DiCaprio", profilePath: "/wo2hJpn04vbtmh0B9utCFHMDk4E.jpg", knownForDepartment: "Diễn viên", popularity: 100),
        Actor(id: 1245, name: "Scarlett Johansson", profilePath: "/6NsMbJXRlDZuDzatN2akFdGuTvx.jpg", knownForDepartment: "Diễn viên", popularity: 95),
        Actor(id: 500, name: "Tom Cruise", profilePath: "/eOh4N19Eh0y4j2xV3tyMOtvjRWk.jpg", knownForDepartment: "Diễn viên", popularity: 92),
        Actor(id: 2524, name: "Tom Hanks", profilePath: "/eKF1sGJRr7FR2x14VxSdARO5H5a.jpg", knownForDepartment: "Diễn viên", popularity: 88),
        Actor(id: 17419, name: "Brad Pitt", profilePath: "/cckcYc2v0yh6J4kY5tP1jwDhT2.jpg", knownForDepartment: "Diễn viên", popularity: 85),
        Actor(id: 1136406, name: "Margot Robbie", profilePath: "/euDPyqLnuS4pGPhp8iVtFyS2GA.jpg", knownForDepartment: "Diễn viên", popularity: 90),
        Actor(id: 1892, name: "Matt Damon", profilePath: "/eQ4B3F2UMjMx9Dz3nBVFhGqE1o.jpg", knownForDepartment: "Diễn viên", popularity: 75),
        Actor(id: 380, name: "Robert De Niro", profilePath: "/cT8htcckIuyI1Lqwt1CvDcA0RZ.jpg", knownForDepartment: "Diễn viên", popularity: 80),
        Actor(id: 287, name: "Bradley Cooper", profilePath: "/jJtUzRG8I36CVLqVr7B0lB0r0V.jpg", knownForDepartment: "Diễn viên", popularity: 82),
        Actor(id: 234352, name: "Florence Pugh", profilePath: "/8fV8Vw0hBzKwCo4S4vL1jYP2z.jpg", knownForDepartment: "Diễn viên", popularity: 78),
        Actor(id: 1289967, name: "Timothée Chalamet", profilePath: "/6l2Z7fT0IyqLFkqQl8ZR0OmBt.jpg", knownForDepartment: "Diễn viên", popularity: 88),
        Actor(id: 4495, name: "Joaquin Phoenix", profilePath: "/qL0IHuSfVwW1EtMK2AnXjzmRL.jpg", knownForDepartment: "Diễn viên", popularity: 72),
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Diễn viên hot")
                        .font(.largeTitle.bold()).foregroundColor(.white)
                        .padding(.top, 70).padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Tìm diễn viên...", text: $searchText)
                            .foregroundColor(.white)
                            .onChange(of: searchText) { _ in
                                filterActors()
                            }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.3)))
                    .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(actors) { actor in
                            Button {
                                selectedActor = actor
                            } label: {
                                VStack(spacing: 8) {
                                    if let url = actor.profileURL {
                                        CachedAsyncImage(url: url)
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                                    } else {
                                        Circle()
                                            .fill(.ultraThinMaterial.opacity(0.4))
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                Text(String(actor.name.prefix(1)))
                                                    .font(.system(size: 30, weight: .bold))
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    Text(actor.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                    if let known = actor.knownForDepartment {
                                        Text(known)
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer().frame(height: 100)
                }
            }
            backButton
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedActor) { actor in
            ActorDetailView(actor: actor)
        }
        .task {
            actors = fakeActors
        }
    }
    
    func filterActors() {
        if searchText.isEmpty {
            actors = fakeActors
        } else {
            actors = fakeActors.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12)
                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5)))
        }.padding(.top, 54).padding(.leading, 16)
    }
}

// MARK: - This Day History
struct ThisDayHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var movies: [Movie] = []
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Ngày này năm xưa").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(Array(movies.prefix(8).enumerated()), id: \.offset) { _, m in
                        NavigationLink(destination: MovieDetailView(movie: m)) {
                            HStack(spacing: 12) {
                                CachedAsyncImage(url: m.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 60, height: 90).clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(m.title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                    Text(m.releaseDate ?? "").font(.caption).foregroundColor(.gray)
                                    Text(m.overview).font(.system(size: 11)).foregroundColor(.white.opacity(0.6)).lineLimit(3)
                                }
                                Spacer()
                            }.padding(12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.2)))
                        }.padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            backButton
        }.navigationBarHidden(true).task { movies = (try? await APIService.shared.topRated()) ?? [] }
    }
    var backButton: some View {
        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 16)
    }
}

// MARK: - Pair View
struct PairView: View {
    @Environment(\.dismiss) var dismiss
    let pairs: [(String, String, Int)] = [
        ("Brad Pitt", "Leonardo DiCaprio", 2), ("Tom Hanks", "Meg Ryan", 4),
        ("Emma Stone", "Ryan Gosling", 3), ("Robert De Niro", "Al Pacino", 4),
        ("Johnny Depp", "Helena Bonham Carter", 7), ("Scarlett Johansson", "Chris Evans", 8),
        ("Jennifer Lawrence", "Bradley Cooper", 4), ("Keanu Reeves", "Sandra Bullock", 2)
    ]
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Cặp bài trùng").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(pairs, id: \.0) { a, b, count in
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                VStack(spacing: 6) {
                                    Circle().fill(.ultraThinMaterial.opacity(0.4)).frame(width: 70, height: 70).overlay(Text(String(a.prefix(1))).font(.system(size: 30, weight: .bold)).foregroundColor(.white))
                                    Text(a).font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                                }
                                Text("❤️").font(.system(size: 20))
                                VStack(spacing: 6) {
                                    Circle().fill(.ultraThinMaterial.opacity(0.4)).frame(width: 70, height: 70).overlay(Text(String(b.prefix(1))).font(.system(size: 30, weight: .bold)).foregroundColor(.white))
                                    Text(b).font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                                }
                            }
                            Text("Đã đóng chung \(count) phim").font(.system(size: 13, weight: .medium)).foregroundColor(.pink).padding(.vertical, 4).padding(.horizontal, 12).background(Capsule().fill(.pink.opacity(0.15)))
                        }.padding(16).background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.25))).overlay(RoundedRectangle(cornerRadius: 18).stroke(.pink.opacity(0.15), lineWidth: 0.5)).padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            backButton
        }.navigationBarHidden(true)
    }
    var backButton: some View {
        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 16)
    }
}

// MARK: - Compare View
struct CompareView: View {
    @Environment(\.dismiss) var dismiss
    @State private var m1: Movie?; @State private var m2: Movie?
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("So sánh phim").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    if let a = m1, let b = m2 {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                VStack(spacing: 6) {
                                    CachedAsyncImage(url: a.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(a.title).font(.system(size: 11, weight: .semibold)).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.center)
                                }
                                VStack(spacing: 8) {
                                    Text("VS").font(.system(size: 22, weight: .black)).foregroundColor(.red)
                                    VStack(spacing: 4) {
                                        CompareRow(label: "Điểm", left: a.ratingText, right: b.ratingText)
                                        CompareRow(label: "Năm", left: a.releaseDate ?? "-", right: b.releaseDate ?? "-")
                                    }
                                }
                                VStack(spacing: 6) {
                                    CachedAsyncImage(url: b.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(b.title).font(.system(size: 11, weight: .semibold)).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.center)
                                }
                            }
                        }.padding(16).background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.25))).padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            backButton
        }.navigationBarHidden(true).task { let movies = (try? await APIService.shared.popular()) ?? []; m1 = movies.first; m2 = movies.dropFirst().first }
    }
    var backButton: some View {
        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 16)
    }
}

struct CompareRow: View {
    let label: String; let left: String; let right: String
    var body: some View {
        HStack(spacing: 8) {
            Text(left).font(.system(size: 11, weight: .bold)).foregroundColor(.yellow).frame(width: 50)
            Text(label).font(.system(size: 10)).foregroundColor(.gray).frame(width: 40)
            Text(right).font(.system(size: 11, weight: .bold)).foregroundColor(.yellow).frame(width: 50)
        }
    }
}

// MARK: - Universe View
struct UniverseView: View {
    @Environment(\.dismiss) var dismiss
    let universes: [(String, Int, CategoryConfig.CategoryType)] = [
        ("Marvel Studios", 420, .studio), ("DC Extended", 429, .studio),
        ("Star Wars", 1, .studio), ("Wizarding World", 174, .studio),
        ("Jurassic Saga", 56, .studio), ("Fast Saga", 3325, .studio),
        ("James Bond", 214, .studio), ("Transformers", 248, .studio)
    ]
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    Text("Vũ trụ điện ảnh").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(universes, id: \.0) { name, tmdbId, type in
                        NavigationLink(destination: CategoryFullView(category: CategoryConfig(id: 0, name: name, posterName: "", type: type, tmdbId: tmdbId))) {
                            HStack(spacing: 12) { VStack(alignment: .leading) { Text(name).font(.system(size: 16, weight: .semibold)).foregroundColor(.white); Text("Xem tất cả phim").font(.caption).foregroundColor(.gray) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray) }.padding(.horizontal, 16).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.25)))
                        }
                    }
                    Spacer().frame(height: 120)
                }
            }
            backButton
        }.navigationBarHidden(true)
    }
    var backButton: some View {
        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 16)
    }
}

// MARK: - CategoryFullView
struct CategoryFullView: View {
    let category: CategoryConfig
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if isLoading && movies.isEmpty { ProgressView().tint(.white) }
            else if movies.isEmpty { Text("Không tìm thấy").foregroundColor(.gray) }
            else { ScrollView { LazyVGrid(columns: columns, spacing: 16) { ForEach(movies) { movie in NavigationLink(destination: MovieDetailView(movie: movie)) { VStack(spacing: 6) { CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 4, y: 2); Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2); HStack(spacing: 2) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray) } }.padding(6).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2))) } } }.padding(.horizontal, 16).padding(.top, 90).padding(.bottom, 100) } }
            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 16)
        }.navigationBarHidden(true).task { do { movies = try await APIService.shared.fetchMovies(by: category.tmdbId, type: category.type) } catch { movies = [] }; isLoading = false }
    }
}