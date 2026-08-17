import SwiftUI

// MARK: - Explore View
struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @State private var staffMovies: [Movie] = []
    @State private var editorMovies: [Movie] = []
    @State private var hiddenMovies: [Movie] = []
    
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
                        
                        // 2 nút: OST | Timeline
                        HStack(spacing: 10) {
                            NavigationLink(destination: OSTView()) {
                                HStack(spacing: 6) {
                                    Text("🎵").font(.system(size: 14))
                                    Text("OST").font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 0.5))
                            }
                            
                            NavigationLink(destination: TimelineView()) {
                                HStack(spacing: 6) {
                                    Text("📅").font(.system(size: 14))
                                    Text("Timeline").font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 0.5))
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

// Giữ nguyên AsiaCategoryView, BackButton, CategoryFullView bên dưới không đổi


// MARK: - Asia Category View
struct AsiaCategoryView: View {
    @State private var selectedCountry = "all"
    @State private var allMovies: [Movie] = []
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    let countries: [(String, String)] = [
        ("all", "Tất cả"), ("ko", "Hàn Quốc"), ("zh", "Trung Quốc"), ("ja", "Nhật Bản"),
        ("vi", "Việt Nam"), ("th", "Thái Lan"), ("cn", "Hong Kong")
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(countries, id: \.0) { code, name in
                            Button { selectedCountry = code; filterMovies() } label: {
                                Text(name).font(.system(size: 13, weight: selectedCountry == code ? .bold : .regular))
                                    .foregroundColor(selectedCountry == code ? .white : .gray)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(selectedCountry == code ? Material.regularMaterial.opacity(0.5) : Material.regularMaterial.opacity(0.2)))
                                    .overlay(Capsule().stroke(.white.opacity(selectedCountry == code ? 0.2 : 0.05), lineWidth: 0.5))
                            }
                        }
                    }.padding(.horizontal, 16)
                }.padding(.top, 60).padding(.bottom, 8)
                
                if isLoading { Spacer(); ProgressView().tint(.white); Spacer() }
                else if movies.isEmpty { Spacer(); Text("Không tìm thấy").foregroundColor(.gray); Spacer() }
                else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 6) {
                                        CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                        Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                        HStack(spacing: 2) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray) }
                                    }.padding(6).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                                }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 100)
                    }
                }
            }
            BackButton()
        }.navigationBarHidden(true)
        .task { allMovies = (try? await APIService.shared.fetchAsiaMovies(language: nil)) ?? []; filterMovies(); isLoading = false }
    }
    
    func filterMovies() { if selectedCountry == "all" { movies = allMovies } else { movies = allMovies.filter { $0.originalLanguage == selectedCountry } } }
}

// MARK: - Back Button Helper
struct BackButton: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))) }.padding(.top, 54).padding(.leading, 16)
    }
}

// MARK: - CategoryFullView
struct CategoryFullView: View {
    let category: CategoryConfig
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var currentPage = 1
    @State private var totalPages = 1
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
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Title
                            Text(category.name)
                                .font(.title2).fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 80)
                                .id("top")
                            
                            // Grid phim
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(movies) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        VStack(spacing: 6) {
                                            CachedAsyncImage(url: movie.posterURL)
                                                .aspectRatio(2/3, contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                            Text(movie.title)
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                            HStack(spacing: 2) {
                                                Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                                Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                            }
                                        }
                                        .padding(6)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.2)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Phân trang - chỉ hiện nếu > 1 trang
                            if totalPages > 1 {
                                HStack(spacing: 12) {
                                    Button {
                                        if currentPage > 1 {
                                            currentPage -= 1
                                            Task { 
                                                await loadPage(currentPage)
                                                withAnimation { proxy.scrollTo("top", anchor: .top) }
                                            }
                                        }
                                    } label: {
                                        Text("< trước")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(currentPage > 1 ? .white : .gray.opacity(0.5))
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(1...min(totalPages, 10), id: \.self) { page in
                                                Button {
                                                    currentPage = page
                                                    Task { 
                                                        await loadPage(page)
                                                        withAnimation { proxy.scrollTo("top", anchor: .top) }
                                                    }
                                                } label: {
                                                    Text("\(page)")
                                                        .font(.system(size: 12, weight: page == currentPage ? .bold : .regular))
                                                        .foregroundColor(page == currentPage ? .black : .white)
                                                        .frame(width: 28, height: 28)
                                                        .background(page == currentPage ? .white : .white.opacity(0.1))
                                                        .clipShape(Circle())
                                                }
                                            }
                                            
                                            if totalPages > 10 {
                                                Text("...")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                                
                                                Button {
                                                    currentPage = totalPages
                                                    Task { 
                                                        await loadPage(totalPages)
                                                        withAnimation { proxy.scrollTo("top", anchor: .top) }
                                                    }
                                                } label: {
                                                    Text("\(totalPages)")
                                                        .font(.system(size: 12, weight: totalPages == currentPage ? .bold : .regular))
                                                        .foregroundColor(totalPages == currentPage ? .black : .white)
                                                        .frame(width: 28, height: 28)
                                                        .background(totalPages == currentPage ? .white : .white.opacity(0.1))
                                                        .clipShape(Circle())
                                                }
                                            }
                                        }
                                    }
                                    
                                    Button {
                                        if currentPage < totalPages {
                                            currentPage += 1
                                            Task { 
                                                await loadPage(currentPage)
                                                withAnimation { proxy.scrollTo("top", anchor: .top) }
                                            }
                                        }
                                    } label: {
                                        Text("sau >")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(currentPage < totalPages ? .white : .gray.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }
                            
                            Spacer().frame(height: 50)
                        }
                    }
                }
            }
            
            BackButton()
        }
        .navigationBarHidden(true)
        .task {
            await loadPage(1)
            isLoading = false
        }
    }
    
    func loadPage(_ page: Int) async {
        do {
            let all = try await APIService.shared.fetchMovies(by: category.tmdbId, type: category.type)
            let filtered = all.filter { !($0.adult ?? false) }
            await MainActor.run {
                movies = Array(filtered.prefix(30))
                totalPages = max(1, Int(ceil(Double(filtered.count) / 30.0)))
            }
        } catch {
            await MainActor.run {
                movies = []
                totalPages = 1
            }
        }
    }
}