import SwiftUI

// MARK: - Explore View
struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @State private var staffMovies: [Movie] = []; @State private var editorMovies: [Movie] = []; @State private var hiddenMovies: [Movie] = []
    @State private var showSwipePick = false
    
    let collections: [(String, Int, CategoryConfig.CategoryType)] = [
    ("IMDb Top", 210024, .keyword),
    ("Netflix", 213, .studio), ("Marvel", 420, .studio),
    ("DC", 429, .studio), ("Pixar", 3, .studio), ("Disney", 2, .studio),
    ("HBO", 49, .studio), ("Apple TV+", 2552, .studio), ("Amazon Prime", 1024, .studio),
    ("Disney+", 2739, .studio), ("Hulu", 453, .studio), ("Paramount+", 4330, .studio),
    ("Peacock", 3353, .studio), ("Anime", 16, .genre), ("Châu Á", 0, .asia), ("Warner Bros", 174, .studio)
]
    
    let posterMap: [String: String] = [
    "IMDb Top": "/8Tfys3mDZVp4tNoH2ktm06a0Tau.jpg",
    "Netflix": "/jLuGZc84MvPYCQomQg9DI72mstt.jpg",
    "Marvel": "/lv3TXqhpaIxkclIHbhN2MRMOemQ.jpg",
    "DC": "/eGX66zonvc4bXg3rM08RUxdYSDx.jpg",
    "Pixar": "/u53UYu5XG2hNgWGvs3xGhAVzypl.jpg",
    "Disney": "/qjTqY5coNiz6sVtPng40IzltsoN.jpg",
    "HBO": "/577eXC8wFQT0eUrJcgznSiFPRmk.jpg",
    "Apple TV+": "/yx0sfeYOoXol2fjT22SXo9YyviI.jpg",
    "Amazon Prime": "/voKEhzb4ExOmR0WSvQgLTTqRUEu.jpg",
    "Disney+": "/q3jHCb4dMfYF6ojikKuHd6LscxC.jpg",
    "Hulu": "/a4doyPOabvQor0RGkWdhVENAR3G.jpg",
    "Paramount+": "/mNHRGO1gFpR2CYZdANe72kcKq7G.jpg",
    "Peacock": "/xaiKpxuf9YGuTsqpdK5HSbD8M8f.jpg",
    "Anime": "/gtKglOSEq3d4MgQE4VsrT1sRkd0.jpg",
    "Châu Á": "/i3bMeXOGyT57owjlMPCuLiijhq5.jpg",
    "Warner Bros": "/1stUIsjawROZxjiCMtqqXqgfZWC.jpg"
]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(white: 0.12), Color(white: 0.05), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Khám phá").font(.largeTitle).fontWeight(.bold).foregroundColor(.white).padding(.top, 8).padding(.horizontal, 16)
                        HStack(spacing: 12) {
                            NavigationLink(destination: OSTView()) {
                                VStack(spacing: 6) {
                                    Image(systemName: "music.note").font(.system(size: 22))
                                    Text("OST").font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(width: (UIScreen.main.bounds.width - 64) / 4, height: (UIScreen.main.bounds.width - 64) / 4)
                                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 0.5))
                            }
                            NavigationLink(destination: FilmHubView()) {
                                VStack(spacing: 6) {
                                    Image(systemName: "film").font(.system(size: 22))
                                    Text("Góc phim").font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(width: (UIScreen.main.bounds.width - 64) / 4, height: (UIScreen.main.bounds.width - 64) / 4)
                                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 0.5))
                            }
                            NavigationLink(destination: TimelineView()) {
                                VStack(spacing: 6) {
                                    Image(systemName: "calendar").font(.system(size: 22))
                                    Text("Timeline").font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(width: (UIScreen.main.bounds.width - 64) / 4, height: (UIScreen.main.bounds.width - 64) / 4)
                                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 0.5))
                            }
                            Button {
                                showSwipePick = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "heart.circle").font(.system(size: 22))
                                    Text("Pick").font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(width: (UIScreen.main.bounds.width - 64) / 4, height: (UIScreen.main.bounds.width - 64) / 4)
                                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 0.5))
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(collections, id: \.0) { title, tmdbId, type in
                                if type == .asia {
                                    NavigationLink(destination: AsiaCategoryView()) {
                                        ZStack(alignment: .bottomLeading) {
                                            RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 100)
                                            if let p = posterMap[title], let url = URL(string: "https://image.tmdb.org/t/p/w500\(p)") {
                                                CachedAsyncImage(url: url).aspectRatio(contentMode: .fill).frame(height: 100).clipShape(RoundedRectangle(cornerRadius: 14))
                                            }
                                            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom).clipShape(RoundedRectangle(cornerRadius: 14))
                                            Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                        }.frame(height: 100)
                                    }
                                } else {
                                    NavigationLink(destination: CategoryFullView(category: CategoryConfig(id: 0, name: title, posterName: "", type: type, tmdbId: tmdbId))) {
                                        ZStack(alignment: .bottomLeading) {
                                            RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 100)
                                            if let p = posterMap[title], let url = URL(string: "https://image.tmdb.org/t/p/w500\(p)") {
                                                CachedAsyncImage(url: url).aspectRatio(contentMode: .fill).frame(height: 100).clipShape(RoundedRectangle(cornerRadius: 14))
                                            }
                                            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom).clipShape(RoundedRectangle(cornerRadius: 14))
                                            Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(8)
                                        }.frame(height: 100)
                                    }
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
        .overlay {
            if showSwipePick {
                SwipePickOverlay(show: $showSwipePick)
                    .environmentObject(appState)
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
        VStack(alignment: .leading, spacing: 10) { Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.horizontal); ScrollView(.horizontal, showsIndicators: false) { LazyHStack(spacing: 12) { ForEach(movies.prefix(20)) { m in NavigationLink(destination: MovieDetailView(movie: m)) { CachedAsyncImage(url: m.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 110, height: 165).clipShape(RoundedRectangle(cornerRadius: 10)) } } }.padding(.horizontal) } }
    }
}

// MARK: - SwipePickOverlay
struct SwipePickOverlay: View {
    @Binding var show: Bool
    @EnvironmentObject var appState: AppState
    @State private var movies: [Movie] = []
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var isLoading = true
    
    var currentMovie: Movie? { guard currentIndex < movies.count else { return nil }; return movies[currentIndex] }
    var nextMovie: Movie? { guard currentIndex + 1 < movies.count else { return nil }; return movies[currentIndex + 1] }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { show = false }
            
            VStack {
                if let movie = currentMovie {
                    VStack(spacing: 20) {
                        ZStack {
                            if let next = nextMovie {
                                cardView(movie: next)
                                    .scaleEffect(0.92)
                                    .offset(y: 12)
                                    .opacity(0.5)
                            }
                            cardView(movie: movie)
                                .offset(x: offset.width)
                                .rotationEffect(.degrees(Double(offset.width / 20)))
                                .gesture(DragGesture()
                                    .onChanged { offset = $0.translation }
                                    .onEnded {
                                        if $0.translation.width > 100 { swipeRight() }
                                        else if $0.translation.width < -100 { swipeLeft() }
                                        else { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { offset = .zero } }
                                    }
                                )
                        }
                        
                        HStack(spacing: 50) {
                            Button { swipeLeft() } label: {
                                Image(systemName: "xmark").font(.system(size: 20, weight: .bold)).foregroundColor(.red).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.6))).overlay(Circle().stroke(.red.opacity(0.3), lineWidth: 1))
                            }
                            Button { swipeRight() } label: {
                                Image(systemName: "heart.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.green).padding(14).background(Circle().fill(.ultraThinMaterial.opacity(0.6))).overlay(Circle().stroke(.green.opacity(0.3), lineWidth: 1))
                            }
                        }
                    }
                    .offset(y: -200)
                }
                Spacer()
            }
            
            if isLoading { ProgressView().tint(.white) }
        }
        .task { await loadMovies() }
    }
    
    func cardView(movie: Movie) -> some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: movie.posterURL)
                .aspectRatio(2/3, contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width - 60, height: UIScreen.main.bounds.height * 0.55)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.6), radius: 25)
            VStack(alignment: .leading, spacing: 3) {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                    .frame(height: 100)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(movie.title).font(.system(size: 17, weight: .bold)).foregroundColor(.white).lineLimit(2)
                            HStack(spacing: 6) {
                                HStack(spacing: 3) { Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 11, weight: .bold)).foregroundColor(.white) }
                                Text(movie.yearText).font(.system(size: 10)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 12)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    
    func loadMovies() async {
        isLoading = true
        movies = (try? await APIService.shared.popular())?.filter { !($0.adult ?? false) }.shuffled() ?? []
        isLoading = false
    }
    
    func swipeRight() {
        if let movie = currentMovie {
            if !appState.favorites.contains(where: { $0.id == movie.id }) {
                appState.favorites.append(movie)
                appState.save()
            }
        }
        withAnimation { offset = CGSize(width: 500, height: 0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { currentIndex += 1; offset = .zero }
    }
    
    func swipeLeft() {
        withAnimation { offset = CGSize(width: -500, height: 0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { currentIndex += 1; offset = .zero }
    }
}

// MARK: - Asia Category View
struct AsiaCategoryView: View {
    @State private var selectedCountry = "all"
    @State private var allMovies: [Movie] = []
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    let countries: [(String, String)] = [
        ("all", "Tất cả"),
        ("ko", "Hàn Quốc"),
        ("zh", "Trung Quốc"),
        ("ja", "Nhật Bản"),
        ("vi", "Việt Nam"),
        ("th", "Thái Lan"),
        ("cn", "Hong Kong")
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(countries, id: \.0) { code, name in
                            Button {
                                selectedCountry = code
                                filterMovies()
                            } label: {
                                Text(name)
                                    .font(.system(size: 13, weight: selectedCountry == code ? .bold : .regular))
                                    .foregroundColor(selectedCountry == code ? .white : .gray)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(selectedCountry == code ? Material.regularMaterial.opacity(0.5) : Material.regularMaterial.opacity(0.2)))
                                    .overlay(Capsule().stroke(.white.opacity(selectedCountry == code ? 0.2 : 0.05), lineWidth: 0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 60)
                .padding(.bottom, 8)
                
                if isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if movies.isEmpty {
                    Spacer()
                    Text("Không tìm thấy").foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 6) {
                                        CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                        Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                            Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                        }
                                    }
                                    .padding(6).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 100)
                    }
                }
            }
            BackButton()
        }
        .navigationBarHidden(true)
        .task {
            allMovies = (try? await APIService.shared.fetchAsiaMovies(language: nil)) ?? []
            filterMovies()
            isLoading = false
        }
    }
    
    func filterMovies() {
        if selectedCountry == "all" { movies = allMovies }
        else { movies = allMovies.filter { $0.originalLanguage == selectedCountry } }
    }
}

// MARK: - Back Button Helper
struct BackButton: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 16)
    }
}

// MARK: - FilmHubView
struct FilmHubView: View {
    @Environment(\.dismiss) var dismiss
    let hubItems: [(String, String, Color)] = [
        ("Diễn viên hot", "Ngôi sao được yêu thích", .orange), ("Đạo diễn tài ba", "Nhà làm phim xuất sắc", .purple),
        ("Ngày này năm xưa", "Phim công chiếu hôm nay", .blue), ("Cặp bài trùng", "Bạn diễn ăn ý nhất", .pink),
        ("Phim bị hủy", "Dự án chưa từng ra mắt", .red), ("Đang bàn tán", "Cộng đồng thảo luận nhiều", .green),
        ("So sánh phim", "Đối đầu điện ảnh", .teal), ("Trước khi xem", "Hướng dẫn thứ tự xem", .mint),
        ("Timeline vũ trụ", "Dòng thời gian các vũ trụ", .indigo), ("Top doanh thu", "Phòng vé toàn cầu", .yellow)
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
                                VStack(spacing: 8) { Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white); Text(subtitle).font(.system(size: 11)).foregroundColor(.gray).lineLimit(1) }.frame(maxWidth: .infinity).padding(.vertical, 28).background(RoundedRectangle(cornerRadius: 16).fill(color.opacity(0.15))).overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.2), lineWidth: 0.5))
                            }
                        }
                    }.padding(.horizontal, 16)
                    Spacer().frame(height: 120)
                }
            }
            BackButton()
        }.navigationBarHidden(true)
    }
    
    @ViewBuilder func hubDestination(for t: String) -> some View {
        switch t {
        case "Diễn viên hot": ActorHotView()
        case "Đạo diễn tài ba": DirectorView(directorName: "Christopher Nolan")
        case "Ngày này năm xưa": ThisDayHistoryView()
        case "Cặp bài trùng": PairView()
        case "Phim bị hủy": CancelledMoviesView()
        case "Đang bàn tán": BuzzView()
        case "So sánh phim": CompareView()
        case "Trước khi xem": BeforeWatchView()
        case "Timeline vũ trụ": UniverseTimelineView()
        case "Top doanh thu": CategoryFullView(category: CategoryConfig(id: 0, name: "Doanh thu", posterName: "", type: .keyword, tmdbId: 210024))
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
    
    let allActors: [Actor] = [
        Actor(id: 6193, name: "Leonardo DiCaprio", character: nil, profilePath: "/wo2hJpn04vbtmh0B9utCFHMDk4E.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 1245, name: "Scarlett Johansson", character: nil, profilePath: "/6NsMbJXRlDZuDzatN2akFdGuTvx.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 500, name: "Tom Cruise", character: nil, profilePath: "/8dPX4Mw53EyHpuLYhYBbJLKepYm.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 2524, name: "Tom Hanks", character: nil, profilePath: "/xndWFsBlClOJFRdhSt4NBwiPq2o.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 17419, name: "Brad Pitt", character: nil, profilePath: "/cckcYc2v0yh6J4kY5tP1jwDhT2.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 1136406, name: "Margot Robbie", character: nil, profilePath: "/euDPyqLnuS4pGPhp8iVtFyS2GA.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 1892, name: "Matt Damon", character: nil, profilePath: "/At3JmdaRfnYlSdOWrSSJmgkNDnK.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 380, name: "Robert De Niro", character: nil, profilePath: "/cT8htcckIuyI1Lqwt1CvDcA0RZ.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 287, name: "Bradley Cooper", character: nil, profilePath: "/jJtUzRG8I36CVLqVr7B0lB0r0V.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 234352, name: "Florence Pugh", character: nil, profilePath: "/8fV8Vw0hBzKwCo4S4vL1jYP2z.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 1289967, name: "Timothée Chalamet", character: nil, profilePath: "/6l2Z7fT0IyqLFkqQl8ZR0OmBt.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 4495, name: "Joaquin Phoenix", character: nil, profilePath: "/qL0IHuSfVwW1EtMK2AnXjzmRL.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 85, name: "Johnny Depp", character: nil, profilePath: "/i2qTg1f1J1qF1g1J1qF1g1J1qF1g.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 22226, name: "Zendaya", character: nil, profilePath: "/p5wTQpTQpTQpTQpTQpTQpTQpT.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 2037, name: "Cillian Murphy", character: nil, profilePath: "/i2qTg1f1J1qF1g1J1qF1g1J1qF1g.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 74568, name: "Chris Hemsworth", character: nil, profilePath: "/lF1g1J1qF1g1J1qF1g1J1qF1g1J.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 71580, name: "Robert Downey Jr.", character: nil, profilePath: "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
        Actor(id: 112, name: "Meryl Streep", character: nil, profilePath: "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: "Diễn viên"),
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Diễn viên hot").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 8) { Image(systemName: "magnifyingglass").foregroundColor(.gray); TextField("Tìm diễn viên...", text: $searchText).foregroundColor(.white).onChange(of: searchText) { _ in filterActors() } }.padding(12).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.3))).padding(.horizontal, 16)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(actors) { actor in
                            Button { selectedActor = actor } label: {
                                VStack(spacing: 8) {
                                    if let url = actor.profileURL { CachedAsyncImage(url: url).aspectRatio(contentMode: .fill).frame(width: 80, height: 80).clipShape(Circle()).overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1)) }
                                    else { Circle().fill(.ultraThinMaterial.opacity(0.4)).frame(width: 80, height: 80).overlay(Text(String(actor.name.prefix(1))).font(.system(size: 30, weight: .bold)).foregroundColor(.gray)) }
                                    Text(actor.name).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.center)
                                }
                            }
                        }
                    }.padding(.horizontal, 16)
                    Spacer().frame(height: 100)
                }
            }
            BackButton()
        }.navigationBarHidden(true).fullScreenCover(item: $selectedActor) { actor in ActorDetailView(actor: actor) }.task { actors = allActors }
    }
    func filterActors() { actors = searchText.isEmpty ? allActors : allActors.filter { $0.name.lowercased().contains(searchText.lowercased()) } }
}

// MARK: - Cancelled Movies View
struct CancelledMoviesView: View {
    @Environment(\.dismiss) var dismiss
    let cancelled: [(String, String, String)] = [
        ("Batgirl", "Warner Bros. hủy dù đã quay xong", "Đạo diễn Adil El Arbi và Bilall Fallah. Phim bị hủy tháng 8/2022 để được khấu trừ thuế."),
        ("Spider-Man 4 (Sam Raimi)", "Sony và Raimi bất đồng sáng tạo", "Sau Spider-Man 3, Raimi muốn làm phần 4 với Vulture và Black Cat nhưng Sony muốn reboot."),
        ("Justice League 2 & 3", "Doanh thu phần 1 thấp, Snyder rời đi", "Zack Snyder lên kế hoạch 3 phần Justice League chống Darkseid. Sau phần 1 gây tranh cãi, WB hủy bỏ."),
        ("Gambit", "Phát triển 10 năm rồi bị hủy", "Channing Tatum gắn bó với vai Gambit từ 2014. Disney mua Fox xong thì hủy dự án."),
        ("Hellboy 3 (Guillermo del Toro)", "Không tìm được kinh phí", "Del Toro muốn kết thúc trilogy nhưng Ron Perlman nói 'Hollywood không muốn bỏ tiền'."),
        ("The Fantastic Four (2015 sequel)", "Doanh thu quá thấp", "Phần reboot 2015 bị chê thảm họa, kế hoạch phần 2 bị Fox hủy ngay lập tức."),
        ("Superman Lives", "Dự án của Tim Burton bị WB hủy", "Nicolas Cage từng được cast làm Superman. Kịch bản có Brainiac, Doomsday. WB sợ rủi ro sau Batman & Robin."),
        ("Alien 5 (Neill Blomkamp)", "Ridley Scott từ chối", "Blomkamp muốn làm phần tiếp theo bỏ qua Alien 3&4, mang Hicks và Newt trở lại. Ridley Scott từ chối hợp tác."),
        ("The Beatles: Yellow Submarine Remake", "Disney hủy sau khi thử nghiệm", "Robert Zemeckis đạo diễn bản remake 3D. Disney hủy vì doanh thu Mars Needs Moms quá thấp."),
        ("Mouse Guard", "Disney mua Fox xong thì hủy", "Dự án chuyển thể từ comic, đạo diễn Wes Ball. Đã cast Andy Serkis, Thomas Brodie-Sangster. Hủy 2 tuần trước khi quay."),
    ]
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Phim bị hủy").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(cancelled, id: \.0) { name, reason, detail in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { Circle().fill(.red).frame(width: 8, height: 8); Text(name).font(.system(size: 16, weight: .bold)).foregroundColor(.white) }
                            Text(reason).font(.system(size: 12)).foregroundColor(.orange)
                            Text(detail).font(.system(size: 12)).foregroundColor(.gray).lineLimit(4)
                        }.padding(14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.2))).padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            BackButton()
        }.navigationBarHidden(true)
    }
}

// MARK: - Buzz View
struct BuzzView: View {
    @Environment(\.dismiss) var dismiss
    let buzzItems: [(String, String, Int)] = [
        ("Squid Game 2", "Netflix", 12500), ("Stranger Things 5", "Netflix", 10200),
        ("Superman: Legacy", "DC Studios", 9800), ("Deadpool & Wolverine", "Marvel Studios", 14500),
        ("The Last of Us 2", "HBO", 8700), ("Joker: Folie à Deux", "Warner Bros", 11200),
        ("Avatar 3", "20th Century", 10800), ("The Batman 2", "DC", 9300),
        ("Fantastic Four", "Marvel", 8900), ("Mickey 17", "Warner Bros", 7200)
    ]
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Đang bàn tán").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Tuần này cộng đồng đang nói về...").font(.caption).foregroundColor(.gray).padding(.horizontal, 16)
                    ForEach(buzzItems, id: \.0) { name, studio, count in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) { Text(name).font(.system(size: 15, weight: .semibold)).foregroundColor(.white); Text(studio).font(.caption).foregroundColor(.gray) }
                            Spacer()
                            HStack(spacing: 4) { Image(systemName: "text.bubble.fill").font(.system(size: 10)).foregroundColor(.green); Text("\(count)+").font(.system(size: 12, weight: .bold)).foregroundColor(.green) }
                        }.padding(12).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.2))).padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            BackButton()
        }.navigationBarHidden(true)
    }
}

// MARK: - Before Watch View
struct BeforeWatchView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Trước khi xem").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(beforeWatchData, id: \.0) { title, items in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.horizontal, 16)
                            ForEach(items, id: \.self) { item in
                                HStack(spacing: 10) { Image(systemName: item.hasPrefix("→") ? "arrow.right.circle.fill" : "checkmark.circle.fill").font(.system(size: 12)).foregroundColor(.blue); Text(item).font(.system(size: 13)).foregroundColor(.white.opacity(0.8)) }.padding(.horizontal, 16)
                            }
                        }.padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.15))).padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            BackButton()
        }.navigationBarHidden(true)
    }
    
    let beforeWatchData: [(String, [String])] = [
        ("MCU", ["→ Iron Man", "→ The Incredible Hulk", "→ Iron Man 2", "→ Thor", "→ Captain America", "→ The Avengers", "..."]),
        ("X-Men", ["→ X-Men: First Class", "→ X-Men Origins: Wolverine", "→ X-Men", "→ X2", "→ X-Men: The Last Stand", "→ The Wolverine", "..."]),
        ("DC Extended", ["→ Man of Steel", "→ Batman v Superman", "→ Suicide Squad", "→ Wonder Woman", "→ Justice League", "→ Aquaman", "..."]),
        ("Star Wars", ["→ Episode I: The Phantom Menace", "→ Episode II: Attack of the Clones", "→ The Clone Wars (series)", "→ Episode III: Revenge of the Sith", "→ Solo", "→ Obi-Wan Kenobi", "..."]),
        ("Fast & Furious", ["→ The Fast and the Furious", "→ 2 Fast 2 Furious", "→ Fast & Furious", "→ Fast Five", "→ Fast & Furious 6", "→ Furious 7", "..."]),
        ("Harry Potter", ["→ Harry Potter 1", "→ Harry Potter 2", "→ Harry Potter 3", "→ Harry Potter 4", "→ Harry Potter 5", "→ Harry Potter 6", "→ Harry Potter 7 P1", "→ Harry Potter 7 P2", "→ Fantastic Beasts series"]),
    ]
}

// MARK: - Universe Timeline View
struct UniverseTimelineView: View {
    @Environment(\.dismiss) var dismiss
    let universes: [(String, String, [(String, Int)])] = [
        ("MCU", "🦸", [("Phase 1", 2008), ("Phase 2", 2013), ("Phase 3", 2016), ("Phase 4", 2021), ("Phase 5", 2023), ("Phase 6", 2025)]),
        ("DCEU", "🦇", [("Man of Steel", 2013), ("BvS", 2016), ("Suicide Squad", 2016), ("Wonder Woman", 2017), ("Justice League", 2017), ("Aquaman", 2018)]),
        ("Star Wars", "⭐", [("Prequel Era", 1999), ("Clone Wars", 2008), ("Original Era", 1977), ("Rebels", 2014), ("Sequel Era", 2015), ("New Republic", 2023)]),
        ("Wizarding World", "⚡", [("Fantastic Beasts", 1926), ("Harry Potter 1-7", 1991), ("Cursed Child", 2016)]),
        ("X-Men", "❌", [("First Class", 1962), ("Origins: Wolverine", 1979), ("X-Men", 2000), ("X2", 2003), ("Last Stand", 2006), ("The Wolverine", 2013)]),
        ("Fast Saga", "🏎️", [("F1", 2001), ("2F2F", 2003), ("Tokyo Drift", 2006), ("F&F", 2009), ("Fast Five", 2011), ("F6", 2013)]),
        ("Jurassic", "🦖", [("Jurassic Park", 1993), ("Lost World", 1997), ("JP3", 2001), ("Jurassic World", 2015), ("Fallen Kingdom", 2018), ("Dominion", 2022)]),
        ("Middle-earth", "💍", [("Hobbit 1", 2012), ("Hobbit 2", 2013), ("Hobbit 3", 2014), ("LOTR 1", 2001), ("LOTR 2", 2002), ("LOTR 3", 2003)]),
    ]
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Timeline vũ trụ").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(universes, id: \.0) { name, emoji, phases in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(emoji) \(name)").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            ForEach(phases, id: \.0) { title, year in
                                HStack(spacing: 10) {
                                    Circle().fill(.blue).frame(width: 8, height: 8)
                                    Text(title).font(.system(size: 13)).foregroundColor(.white)
                                    Spacer()
                                    Text("\(year)").font(.system(size: 11)).foregroundColor(.gray)
                                }
                            }
                        }.padding(14).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.2))).padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            BackButton()
        }.navigationBarHidden(true)
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
                                VStack(alignment: .leading, spacing: 4) { Text(m.title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white); Text(m.releaseDate ?? "").font(.caption).foregroundColor(.gray); Text(m.overview).font(.system(size: 11)).foregroundColor(.white.opacity(0.6)).lineLimit(3) }
                                Spacer()
                            }.padding(12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.2)))
                        }.padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            BackButton()
        }.navigationBarHidden(true).task { movies = (try? await APIService.shared.topRated()) ?? [] }
    }
}

// MARK: - Pair View
struct PairView: View {
    @Environment(\.dismiss) var dismiss
    let pairs: [(String, String, String, String, Int)] = [
        ("Brad Pitt", "Leonardo DiCaprio", "/cckcYc2v0yh6J4kY5tP1jwDhT2.jpg", "/wo2hJpn04vbtmh0B9utCFHMDk4E.jpg", 2),
        ("Emma Stone", "Ryan Gosling", "/4V1T1T1T1T1T1T1T1T1T1T1T1T1T.jpg", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", 3),
        ("Scarlett Johansson", "Chris Evans", "/6NsMbJXRlDZuDzatN2akFdGuTvx.jpg", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", 8),
        ("Jennifer Lawrence", "Bradley Cooper", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", "/jJtUzRG8I36CVLqVr7B0lB0r0V.jpg", 4),
        ("Keanu Reeves", "Sandra Bullock", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", 2),
        ("Tom Hanks", "Meg Ryan", "/xndWFsBlClOJFRdhSt4NBwiPq2o.jpg", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", 4),
        ("Robert De Niro", "Al Pacino", "/cT8htcckIuyI1Lqwt1CvDcA0RZ.jpg", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", 4),
        ("Johnny Depp", "Helena Bonham Carter", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", "/1J1qF1g1J1qF1g1J1qF1g1J1qF.jpg", 7),
    ]
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Cặp bài trùng").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(pairs, id: \.0) { a, b, imgA, imgB, count in
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                VStack(spacing: 6) {
                                    CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(imgA)"))
                                        .aspectRatio(contentMode: .fill).frame(width: 70, height: 70).clipShape(Circle())
                                    Text(a).font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                                }
                                Text("❤️").font(.system(size: 20))
                                VStack(spacing: 6) {
                                    CachedAsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w200\(imgB)"))
                                        .aspectRatio(contentMode: .fill).frame(width: 70, height: 70).clipShape(Circle())
                                    Text(b).font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                                }
                            }
                            Text("Đã đóng chung \(count) phim").font(.system(size: 13, weight: .medium)).foregroundColor(.pink).padding(.vertical, 4).padding(.horizontal, 12).background(Capsule().fill(.pink.opacity(0.15)))
                        }.padding(16).background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.25))).overlay(RoundedRectangle(cornerRadius: 18).stroke(.pink.opacity(0.15), lineWidth: 0.5)).padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            BackButton()
        }.navigationBarHidden(true)
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
                                VStack(spacing: 6) { CachedAsyncImage(url: a.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 12)); Text(a.title).font(.system(size: 11, weight: .semibold)).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.center) }
                                VStack(spacing: 8) {
                                    Text("VS").font(.system(size: 22, weight: .black)).foregroundColor(.red)
                                    CompareRow(label: "Điểm", left: a.ratingText, right: b.ratingText)
                                    CompareRow(label: "Năm", left: a.releaseDate ?? "-", right: b.releaseDate ?? "-")
                                }
                                VStack(spacing: 6) { CachedAsyncImage(url: b.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 100, height: 150).clipShape(RoundedRectangle(cornerRadius: 12)); Text(b.title).font(.system(size: 11, weight: .semibold)).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.center) }
                            }
                        }.padding(16).background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.25))).padding(.horizontal, 16)
                    }
                    Spacer().frame(height: 100)
                }
            }
            BackButton()
        }.navigationBarHidden(true).task { let movies = (try? await APIService.shared.popular()) ?? []; m1 = movies.first; m2 = movies.dropFirst().first }
    }
}

struct CompareRow: View {
    let label: String; let left: String; let right: String
    var body: some View { HStack(spacing: 8) { Text(left).font(.system(size: 11, weight: .bold)).foregroundColor(.yellow).frame(width: 50); Text(label).font(.system(size: 10)).foregroundColor(.gray).frame(width: 40); Text(right).font(.system(size: 11, weight: .bold)).foregroundColor(.yellow).frame(width: 50) } }
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
            if isLoading && movies.isEmpty {
                ProgressView().tint(.white)
            } else if movies.isEmpty {
                Text("Không tìm thấy").foregroundColor(.gray)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                VStack(spacing: 6) {
                                    CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                    Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                        Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                    }
                                }
                                .padding(6).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 90).padding(.bottom, 100)
                }
            }
            BackButton()
        }
        .navigationBarHidden(true)
        .task {
            do { movies = try await APIService.shared.fetchMovies(by: category.tmdbId, type: category.type) } catch { movies = [] }
            isLoading = false
        }
    }
}