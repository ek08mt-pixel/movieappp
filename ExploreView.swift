import SwiftUI

// MARK: - Explore View
struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @State private var staffMovies: [Movie] = []
    @State private var editorMovies: [Movie] = []
    @State private var hiddenMovies: [Movie] = []
    @State private var genrePage = 0
    @State private var displayGenres: [Genre] = []
    
    let genrePosters: [String: String] = [
    "Hành Động": "https://media.themoviedb.org/t/p/w500_and_h282_face/2rjI2uXmjitMAaXVO21r9ao7v2j.jpg",
    "Hài Hước": "https://media.themoviedb.org/t/p/w500_and_h282_face/85k0kaoRgGmF6ACq0M61AFxhjLN.jpg",
    "Cartoon Icons": "https://media.themoviedb.org/t/p/w500_and_h282_face/lgGZ2ysbRyAOi2VgIZpp6k8qILj.jpg",
    "Tình Cảm": "https://media.themoviedb.org/t/p/w500_and_h282_face/oQaVV7p916HO5MDI820zzs1pin9.jpg",
    "Kinh Dị": "https://media.themoviedb.org/t/p/w1000_and_h563_face/9ZChoA7J3C3c144vDl6q2QDmERP.jpg",
    "Giật Gân": "https://media.themoviedb.org/t/p/w500_and_h282_face/H5HjE7Xb9N09rbWn1zBfxgI8uz.jpg",
    "Bí Ẩn": "https://media.themoviedb.org/t/p/w1000_and_h563_face/flxau5Iu7bChQHsESqvGZ3FQRaI.jpg",
    "Khoa Học Viễn Tưởng": "https://media.themoviedb.org/t/p/w1000_and_h563_face/6KDDoTq8Vq3HuQHULzuvPiCJbMI.jpg",
    "Kỳ Ảo": "https://media.themoviedb.org/t/p/w500_and_h282_face/9pBv1BOSloAUgAkF0meJWdnbV4Q.jpg",
    "Gia Đình": "https://media.themoviedb.org/t/p/w500_and_h282_face/fBieUo3SdItUrXZE16YxbpjwXIe.jpg",
    "Chính Kịch": "https://media.themoviedb.org/t/p/w500_and_h282_face/yt9m5CiU2MZkQoNl1kqLPODNR4t.jpg",
    "Phiêu Lưu": "https://media.themoviedb.org/t/p/w1000_and_h563_face/bg6ciVcsJiN7Ovx5dnIholRweN0.jpg",
    "Âm Nhạc": "https://media.themoviedb.org/t/p/w500_and_h282_face/jOodAXQo4VovqV8YruBTW63zWDx.jpg",
    "Võ Thuật": "https://media.themoviedb.org/t/p/w1000_and_h563_face/yAEqrOgg6aB2sodeywPM3Pigubr.jpg",
    "Hình Sự": "https://media.themoviedb.org/t/p/w500_and_h282_face/2J283YNxKhxAqHeVegUJ5mzLfGb.jpg",
    "Tâm Lý": "https://media.themoviedb.org/t/p/w1000_and_h563_face/iCTnFRWCtAwW9dYvsgDEF7rEyWM.jpg",
    "Lịch Sử": "https://media.themoviedb.org/t/p/w1000_and_h563_face/qJbDKWdTQd0IicRKqGoVF7QTmTo.jpg",
    "Cổ Trang": "https://media.themoviedb.org/t/p/w1000_and_h563_face/mITjiHXxA5NZzMEG9YG9MB59BrL.jpg",
    "Sinh Tồn": "https://media.themoviedb.org/t/p/w1000_and_h563_face/oTE4lNs4PSG5iIWjqaTdCIFJ4Bs.jpg",
    "Zombie": "https://media.themoviedb.org/t/p/w1000_and_h563_face/pMTQDxyDVCM8EyWwwXRDgN5R7uf.jpg",
    "Siêu Anh Hùng": "https://media.themoviedb.org/t/p/w500_and_h282_face/eQySd26OW7UmCuaeBOL7qy6foMn.jpg",
    "Công Nghệ": "https://media.themoviedb.org/t/p/w500_and_h282_face/drRxbu2OHG0DEENptZ8wI5f0uEU.jpg",
    "Thảm Họa": "https://media.themoviedb.org/t/p/w1000_and_h563_face/cLFbDVfhllIMybpo2fkGNzehiQG.jpg",
    "Xuyên Không": "https://media.themoviedb.org/t/p/w500_and_h282_face/tulwYlHHvreBlIbzfMzzUK0oxAV.jpg",
    "Học Đường": "https://media.themoviedb.org/t/p/w1000_and_h563_face/7I5o1pauNbi9fpp6Bq4OzRjaQfC.jpg",
    "Tài Liệu": "https://media.themoviedb.org/t/p/w500_and_h282_face/qhSfXdkrIzwYsyQ3Z9ehFmO3zjy.jpg",
    "Truyền Hình": "https://media.themoviedb.org/t/p/w500_and_h282_face/zE9W0do2DF7hsdRPho8W3GOb2AA.jpg",
    "BL": "https://media.themoviedb.org/t/p/w500_and_h282_face/oJ98AdaU2zllrsnRSckTC9SBt14.jpg",
    "GL": "https://media.themoviedb.org/t/p/w500_and_h282_face/xG3b2YNEBxYEY67BvsvvJk3n8D7.jpg",
    "Viễn Tây": "https://media.themoviedb.org/t/p/w500_and_h282_face/2fazcnGzMiZm3INR8pCJHdb734w.jpg",
"Thanh Xuân": "https://media.themoviedb.org/t/p/w1000_and_h563_face/vUVPHEo4ayCO4kkNV4k0PbWPmZS.jpg",
]
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
                        // Khung thể loại
VStack(alignment: .leading, spacing: 8) {
    HStack(spacing: 6) {
        VStack(alignment: .leading, spacing: 2) {
            Text("Bạn muốn xem gì hôm nay?")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text("Hành động, tình cảm, kinh dị... Chọn một thể loại và thưởng thức!")
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        Spacer()
        NavigationLink(destination: AllGenresView()) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(8)
                .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
        }
    }
    .padding(.horizontal, 16)
    
    TabView(selection: $genrePage) {
        ForEach(0..<max(1, (displayGenres.count + 3) / 4), id: \.self) { pageIndex in
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Array(displayGenres.enumerated()).filter { $0.offset / 4 == pageIndex }.map { $0.element }, id: \.id) { genre in
                    NavigationLink(destination: GenreMovieView(genre: genre)) {
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 100)
                                if let posterURL = genrePosters[genre.name], let url = URL(string: posterURL) {
    CachedAsyncImage(url: url)
        .aspectRatio(contentMode: .fill)
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 14))
}
                            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            Text(genre.name.replacingOccurrences(of: "Phim ", with: ""))
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(8)
                        }
                        .frame(height: 100)
                    }
                }
            }
            .padding(.horizontal, 16)
            .tag(pageIndex)
        }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .frame(height: 220)
    .onAppear { shuffleGenres() }
    
    // Dots
    HStack(spacing: 4) {
        ForEach(0..<max(1, (displayGenres.count + 3) / 4), id: \.self) { i in
            Capsule()
                .fill(.white.opacity(i == genrePage ? 0.8 : 0.2))
                .frame(width: i == genrePage ? 16 : 5, height: 3)
                .animation(.easeInOut(duration: 0.3), value: genrePage)
        }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 4)
}
.padding(.top, 12)
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
    func shuffleGenres() {
        let allGenres: [Genre] = [
            Genre(id: 28, name: "Hành Động"),
            Genre(id: 35, name: "Hài Hước"),
            Genre(id: 16, name: "Cartoon Icons"),
            Genre(id: 10749, name: "Tình Cảm"),
            Genre(id: 27, name: "Kinh Dị"),
            Genre(id: 53, name: "Giật Gân"),
            Genre(id: 9648, name: "Bí Ẩn"),
            Genre(id: 878, name: "Khoa Học Viễn Tưởng"),
            Genre(id: 14, name: "Kỳ Ảo"),
            Genre(id: 10751, name: "Gia Đình"),
            Genre(id: 18, name: "Chính Kịch"),
            Genre(id: 12, name: "Phiêu Lưu"),
            Genre(id: 10402, name: "Âm Nhạc"),
            Genre(id: 80, name: "Hình Sự"),
            Genre(id: 36, name: "Lịch Sử"),
            Genre(id: 10749, name: "Cổ Trang"),
            Genre(id: 27, name: "Sinh Tồn"),
            Genre(id: 27, name: "Zombie"),
            Genre(id: 28, name: "Siêu Anh Hùng"),
            Genre(id: 878, name: "Công Nghệ"),
            Genre(id: 28, name: "Thảm Họa"),
            Genre(id: 18, name: "Xuyên Không"),
            Genre(id: 35, name: "Học Đường"),
            Genre(id: 99, name: "Tài Liệu"),
            Genre(id: 10770, name: "Truyền Hình"),
            Genre(id: 37, name: "Viễn Tây"),
Genre(id: 10749, name: "Thanh Xuân"),
            Genre(id: 10749, name: "BL"),
            Genre(id: 10749, name: "GL"),
        ]
        displayGenres = Array(allGenres.shuffled().prefix(8))
    }
    @ViewBuilder func movieRow(title: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 10) { Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.horizontal); ScrollView(.horizontal, showsIndicators: false) { LazyHStack(spacing: 12) { ForEach(movies.prefix(20)) { m in NavigationLink(destination: MovieDetailView(movie: m)) { CachedAsyncImage(url: m.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 110, height: 165).clipShape(RoundedRectangle(cornerRadius: 10)) } } }.padding(.horizontal) } }
    }
}
// MARK: - All Genres View
struct AllGenresView: View {
    @Environment(\.dismiss) var dismiss
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    
    // THÊM Ở ĐÂY
    let genrePosters: [String: String] = [
        "Hành Động": "https://media.themoviedb.org/t/p/w500_and_h282_face/2rjI2uXmjitMAaXVO21r9ao7v2j.jpg",
        "Hài Hước": "https://media.themoviedb.org/t/p/w500_and_h282_face/85k0kaoRgGmF6ACq0M61AFxhjLN.jpg",
        "Tình Cảm": "https://media.themoviedb.org/t/p/w500_and_h282_face/oQaVV7p916HO5MDI820zzs1pin9.jpg",
        "Cartoon Icons": "https://media.themoviedb.org/t/p/w500_and_h282_face/lgGZ2ysbRyAOi2VgIZpp6k8qILj.jpg",
        "Kinh Dị": "https://media.themoviedb.org/t/p/w1000_and_h563_face/9ZChoA7J3C3c144vDl6q2QDmERP.jpg",
        "Giật Gân": "https://media.themoviedb.org/t/p/w500_and_h282_face/H5HjE7Xb9N09rbWn1zBfxgI8uz.jpg",
        "Bí Ẩn": "https://media.themoviedb.org/t/p/w1000_and_h563_face/flxau5Iu7bChQHsESqvGZ3FQRaI.jpg",
        "Khoa Học Viễn Tưởng": "https://media.themoviedb.org/t/p/w1000_and_h563_face/6KDDoTq8Vq3HuQHULzuvPiCJbMI.jpg",
        "Kỳ Ảo": "https://media.themoviedb.org/t/p/w500_and_h282_face/9pBv1BOSloAUgAkF0meJWdnbV4Q.jpg",
        "Gia Đình": "https://media.themoviedb.org/t/p/w500_and_h282_face/fBieUo3SdItUrXZE16YxbpjwXIe.jpg",
        "Chính Kịch": "https://media.themoviedb.org/t/p/w500_and_h282_face/yt9m5CiU2MZkQoNl1kqLPODNR4t.jpg",
        "Phiêu Lưu": "https://media.themoviedb.org/t/p/w1000_and_h563_face/bg6ciVcsJiN7Ovx5dnIholRweN0.jpg",
        "Âm Nhạc": "https://media.themoviedb.org/t/p/w500_and_h282_face/jOodAXQo4VovqV8YruBTW63zWDx.jpg",
        "Võ Thuật": "https://media.themoviedb.org/t/p/w1000_and_h563_face/yAEqrOgg6aB2sodeywPM3Pigubr.jpg",
        "Hình Sự": "https://media.themoviedb.org/t/p/w500_and_h282_face/2J283YNxKhxAqHeVegUJ5mzLfGb.jpg",
        "Tâm Lý": "https://media.themoviedb.org/t/p/w1000_and_h563_face/iCTnFRWCtAwW9dYvsgDEF7rEyWM.jpg",
        "Lịch Sử": "https://media.themoviedb.org/t/p/w1000_and_h563_face/qJbDKWdTQd0IicRKqGoVF7QTmTo.jpg",
        "Cổ Trang": "https://media.themoviedb.org/t/p/w1000_and_h563_face/mITjiHXxA5NZzMEG9YG9MB59BrL.jpg",
        "Sinh Tồn": "https://media.themoviedb.org/t/p/w1000_and_h563_face/oTE4lNs4PSG5iIWjqaTdCIFJ4Bs.jpg",
        "Zombie": "https://media.themoviedb.org/t/p/w1000_and_h563_face/pMTQDxyDVCM8EyWwwXRDgN5R7uf.jpg",
        "Siêu Anh Hùng": "https://media.themoviedb.org/t/p/w500_and_h282_face/eQySd26OW7UmCuaeBOL7qy6foMn.jpg",
        "Công Nghệ": "https://media.themoviedb.org/t/p/w500_and_h282_face/drRxbu2OHG0DEENptZ8wI5f0uEU.jpg",
        "Thảm Họa": "https://media.themoviedb.org/t/p/w1000_and_h563_face/cLFbDVfhllIMybpo2fkGNzehiQG.jpg",
        "Xuyên Không": "https://media.themoviedb.org/t/p/w500_and_h282_face/tulwYlHHvreBlIbzfMzzUK0oxAV.jpg",
        "Học Đường": "https://media.themoviedb.org/t/p/w1000_and_h563_face/7I5o1pauNbi9fpp6Bq4OzRjaQfC.jpg",
        "Tài Liệu": "https://media.themoviedb.org/t/p/w500_and_h282_face/qhSfXdkrIzwYsyQ3Z9ehFmO3zjy.jpg",
        "Truyền Hình": "https://media.themoviedb.org/t/p/w500_and_h282_face/zE9W0do2DF7hsdRPho8W3GOb2AA.jpg",
        "Viễn Tây": "https://media.themoviedb.org/t/p/w500_and_h282_face/2fazcnGzMiZm3INR8pCJHdb734w.jpg",
        "Thanh Xuân": "https://media.themoviedb.org/t/p/w1000_and_h563_face/vUVPHEo4ayCO4kkNV4k0PbWPmZS.jpg",
        "BL": "https://media.themoviedb.org/t/p/w500_and_h282_face/oJ98AdaU2zllrsnRSckTC9SBt14.jpg",
        "GL": "https://media.themoviedb.org/t/p/w500_and_h282_face/xG3b2YNEBxYEY67BvsvvJk3n8D7.jpg"
    ]
    
    
    let allGenres: [Genre] = [
        Genre(id: 28, name: "Hành Động"),
        Genre(id: 35, name: "Hài Hước"),
        Genre(id: 16, name: "Cartoon Icons"),
        Genre(id: 10749, name: "Tình Cảm"),
        Genre(id: 27, name: "Kinh Dị"),
        Genre(id: 53, name: "Giật Gân"),
        Genre(id: 9648, name: "Bí Ẩn"),
        Genre(id: 878, name: "Khoa Học Viễn Tưởng"),
        Genre(id: 14, name: "Kỳ Ảo"),
        Genre(id: 10751, name: "Gia Đình"),
        Genre(id: 18, name: "Chính Kịch"),
        Genre(id: 12, name: "Phiêu Lưu"),
        Genre(id: 10402, name: "Âm Nhạc"),
        Genre(id: 80, name: "Hình Sự"),
        Genre(id: 36, name: "Lịch Sử"),
        Genre(id: 10749, name: "Cổ Trang"),
        Genre(id: 27, name: "Sinh Tồn"),
        Genre(id: 27, name: "Zombie"),
        Genre(id: 28, name: "Siêu Anh Hùng"),
        Genre(id: 878, name: "Công Nghệ"),
        Genre(id: 28, name: "Thảm Họa"),
        Genre(id: 18, name: "Xuyên Không"),
        Genre(id: 35, name: "Học Đường"),
        Genre(id: 99, name: "Tài Liệu"),
        Genre(id: 10770, name: "Truyền Hình"),
        Genre(id: 37, name: "Viễn Tây"),
Genre(id: 10749, name: "Thanh Xuân"),
        Genre(id: 10749, name: "BL"),
        Genre(id: 10749, name: "GL"),
    ]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tất cả thể loại")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 80)
                        .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(allGenres, id: \.name) { genre in
                            NavigationLink(destination: MovieListView(title: genre.name, movies: [], fixedQuery: genre.name)) {
                                ZStack(alignment: .bottomLeading) {
                                    RoundedRectangle(cornerRadius: 14)
    .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
    .frame(height: 100)

if let posterURL = genrePosters[genre.name], let url = URL(string: posterURL) {
    CachedAsyncImage(url: url)
        .aspectRatio(contentMode: .fill)
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 14))
}

LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    Text(genre.name)
                                        .font(.caption).fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(8)
                                }
                                .frame(height: 100)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            
            BackButton()
        }
        .navigationBarHidden(true)
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
    @State private var allMovies: [Movie] = []
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
                            Text(category.name)
                                .font(.title2).fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 80)
                                .id("top")
                            
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
                            
                            // Chỉ hiện số trang, căn giữa
                            if totalPages > 1 {
                                HStack(spacing: 8) {
                                    ForEach(1...totalPages, id: \.self) { page in
                                        Button {
                                            currentPage = page
                                            loadPageData()
                                            withAnimation { proxy.scrollTo("top", anchor: .top) }
                                        } label: {
                                            Text("\(page)")
                                                .font(.system(size: 12, weight: page == currentPage ? .bold : .regular))
                                                .foregroundColor(page == currentPage ? .black : .white)
                                                .frame(width: 28, height: 28)
                                                .background(page == currentPage ? .white : .white.opacity(0.1))
                                                .clipShape(Circle())
                                        }
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
            do {
                allMovies = try await APIService.shared.fetchMovies(by: category.tmdbId, type: category.type)
                    .filter { !($0.adult ?? false) }
                totalPages = max(1, Int(ceil(Double(allMovies.count) / 30.0)))
                loadPageData()
            } catch {
                allMovies = []
                totalPages = 1
            }
            isLoading = false
        }
    }
    
    func loadPageData() {
        let start = (currentPage - 1) * 30
        let end = min(start + 30, allMovies.count)
        if start < allMovies.count {
            movies = Array(allMovies[start..<end])
        } else {
            movies = []
        }
    }
}
