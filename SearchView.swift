import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    @State private var selectedActor: Actor?
    @State private var searchMode: SearchMode = .movies
    @State private var actors: [Actor] = []
    
    enum SearchMode: String, CaseIterable { case movies = "Phim", actors = "Diễn viên" }
    
    var onSelectMovie: ((Movie) -> Void)?
    
    private let columns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    private let actorColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar + toggle
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField(searchMode == .movies ? "Tìm phim..." : "Tìm diễn viên...", text: $vm.query).focused($focused).foregroundColor(.white)
                                .onChange(of: vm.query) { _ in Task { await performSearch() } }
                            if !vm.query.isEmpty { Button { vm.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) } }
                            if focused { Button("Đóng") { focused = false }.foregroundColor(.white).font(.caption) }
                        }
                        .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                        
                        // Toggle Phim / Diễn viên
                        Picker("", selection: $searchMode) {
                            ForEach(SearchMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: searchMode) { _ in
                            vm.query = ""
                            actors = []
                            vm.results = []
                            Task { await performSearch() }
                        }
                    }
                    .padding(.horizontal).padding(.top, 54)
                    
                    if vm.query.isEmpty && searchMode == .movies {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass").font(.system(size: 40)).foregroundColor(.gray)
                            Text("Tìm phim, TV show...").foregroundColor(.gray)
                        }.frame(maxHeight: .infinity)
                    } else if searchMode == .movies {
                        if vm.results.isEmpty {
                            VStack(spacing: 12) { Image(systemName: "movieclapper").font(.system(size: 40)).foregroundColor(.gray); Text("Không tìm thấy").foregroundColor(.gray) }.frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(vm.results) { movie in
                                        Button {
                                            if let callback = onSelectMovie { callback(movie); dismiss() }
                                            else { selectedMovie = movie }
                                        } label: {
                                            VStack(spacing: 6) {
                                                CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 3).overlay(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.12)).opacity(movie.posterURL == nil ? 1 : 0))
                                                Text(movie.title).font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                                HStack(spacing: 2) { Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow); Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray) }
                                            }
                                        }
                                    }
                                }.padding(.horizontal, 16).padding(.bottom, 100)
                            }
                        }
                    } else if searchMode == .actors {
                        if actors.isEmpty {
                            VStack(spacing: 12) { Image(systemName: "person.fill.questionmark").font(.system(size: 40)).foregroundColor(.gray); Text("Không tìm thấy diễn viên").foregroundColor(.gray) }.frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: actorColumns, spacing: 14) {
                                    ForEach(actors) { actor in
                                        Button { selectedActor = actor } label: {
                                            VStack(spacing: 8) {
                                                if let url = actor.profileURL {
                                                    CachedAsyncImage(url: url).aspectRatio(contentMode: .fill).frame(width: 80, height: 80).clipShape(Circle()).overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                                                } else {
                                                    Circle().fill(.ultraThinMaterial.opacity(0.4)).frame(width: 80, height: 80).overlay(Text(String(actor.name.prefix(1))).font(.system(size: 30, weight: .bold)).foregroundColor(.gray))
                                                }
                                                Text(actor.name).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.center)
                                            }
                                        }
                                    }
                                }.padding(.horizontal, 16).padding(.bottom, 100)
                            }
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedMovie) { movie in MovieDetailView(movie: movie) }
            .fullScreenCover(item: $selectedActor) { actor in ActorDetailView(actor: actor) }
        }
        .onAppear { focused = true; Task { await vm.loadTrending() } }
    }
    
    func performSearch() async {
        if searchMode == .movies {
            await vm.search()
        } else {
            guard vm.query.count >= 2 else { actors = []; return }
            // Search actors qua TMDB API
            let query = vm.query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vm.query
            let urlString = "https://api.themoviedb.org/3/search/person?api_key=b6be36c1c5788565fec6a24811e7cc9b&language=vi-VN&query=\(query)"
            guard let url = URL(string: urlString) else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                struct PersonResponse: Codable { let results: [PersonResult] }
                struct PersonResult: Codable {
                    let id: Int; let name: String; let profile_path: String?; let known_for_department: String?
                }
                let response = try JSONDecoder().decode(PersonResponse.self, from: data)
                await MainActor.run {
                    actors = response.results.map { Actor(id: $0.id, name: $0.name, character: nil, profilePath: $0.profile_path, biography: nil, birthday: nil, placeOfBirth: nil, knownForDepartment: $0.known_for_department) }
                }
            } catch { print("Search actors error: \(error)") }
        }
    }
}