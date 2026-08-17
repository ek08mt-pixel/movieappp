import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedMovie: Movie?
    @State private var selectedActor: Actor?
    @State private var recommendedMovie: Movie?
    @State private var recommendedMovies: [Movie] = []
    @State private var showEmmewChat = false
    @State private var emmewQuestion = ""
    @State private var emmewResponse = ""
    @State private var isEmmewThinking = false
    @State private var searchMode: SearchMode = .movies
    @State private var actors: [Actor] = []
    @State private var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    @State private var currentRecommendIndex = 0
    
    enum SearchMode: String, CaseIterable { case movies = "Phim", actors = "Diễn viên" }
    
    var onSelectMovie: ((Movie) -> Void)?
    
    private let columns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    private let actorColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                ZStack {
                    Color.black.opacity(0.75)
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                }
                .ignoresSafeArea()
                .onTapGesture {
                    focused = false
                }
                
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField(searchMode == .movies ? "Tìm phim..." : "Tìm diễn viên...", text: $vm.query)
                                .focused($focused)
                                .foregroundColor(.white)
                                .onSubmit { saveSearch(vm.query) }
                                .onChange(of: vm.query) { _ in Task { await performSearch() } }
                            if !vm.query.isEmpty {
                                Button { vm.query = "" } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                                }
                            }
                            if focused {
                                Button("Đóng") { focused = false }
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                        .onTapGesture {
                            focused = true
                        }
                        
                        Picker("", selection: $searchMode) {
                            ForEach(SearchMode.allCases, id: \.self) { mode in Text(mode.rawValue).tag(mode) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: searchMode) { _ in
                            vm.query = ""
                            actors = []
                            vm.results = vm.trending
                            focused = false
                        }
                    }
                    .padding(.horizontal).padding(.top, 54)
                    
                    if vm.query.isEmpty && searchMode == .movies {
                        ScrollView {
                            if !recentSearches.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Tìm kiếm gần đây").font(.system(size: 13, weight: .semibold)).foregroundColor(.gray)
                                        Spacer()
                                        Button("Xóa tất cả") {
                                            recentSearches.removeAll()
                                            saveRecent()
                                        }
                                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(recentSearches, id: \.self) { term in
                                            HStack(spacing: 6) {
                                                Button {
                                                    vm.query = term
                                                    Task { await performSearch() }
                                                } label: {
                                                    Text(term)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.white)
                                                }
                                                Button {
                                                    recentSearches.removeAll { $0 == term }
                                                    saveRecent()
                                                } label: {
                                                    Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundColor(.white.opacity(0.6))
                                                }
                                            }
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.4)))
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 0.5))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .padding(.top, 16)
                            }
                            
                            if let movie = recommendedMovie {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Emmew Recommended")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(movie.title)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                            
                                            if let year = movie.releaseDate?.prefix(4) {
                                                Text("\(year) • Phim bộ • FHD")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            HStack(spacing: 8) {
                                                Button {
                                                    Task { await loadAnotherRecommend() }
                                                } label: {
                                                    Text("Rcm lại")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                                        .background(Capsule().fill(.white.opacity(0.1)))
                                                }
                                                
                                                Button {
                                                    selectedMovie = movie
                                                } label: {
                                                    Text("Xem ngay")
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                                        .background(Capsule().fill(.white))
                                                }
                                                
                                                Button {
                                                    showEmmewChat = true
                                                } label: {
                                                    Text("Hỏi Emmew")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(.yellow)
                                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                                        .background(Capsule().fill(.yellow.opacity(0.15)))
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        CachedAsyncImage(url: movie.posterURL)
                                            .aspectRatio(2/3, contentMode: .fill)
                                            .frame(width: 80, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial.opacity(0.4)))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15), lineWidth: 0.5))
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            }
                        }
                    } else if searchMode == .movies {
                        if vm.results.isEmpty && !vm.query.isEmpty {
                            VStack(spacing: 12) { Image(systemName: "movieclapper").font(.system(size: 40)).foregroundColor(.gray); Text("Không tìm thấy").foregroundColor(.gray) }.frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(vm.results) { movie in
                                        Button {
                                            saveSearch(movie.title)
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
                        if actors.isEmpty && !vm.query.isEmpty {
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
            .sheet(isPresented: $showEmmewChat) {
                EmmewChatView(movies: recommendedMovies)
            }
        }
        .onAppear {
            Task {
                await vm.loadTrending()
                if vm.results.isEmpty {
                    vm.results = vm.trending
                }
                if recommendedMovie == nil {
                    recommendedMovie = vm.results.randomElement()
                    await loadRecommended()
                }
            }
        }
    }
    
    func saveSearch(_ term: String) {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        recentSearches.removeAll { $0 == term }
        recentSearches.insert(term, at: 0)
        if recentSearches.count > 10 { recentSearches = Array(recentSearches.prefix(10)) }
        saveRecent()
    }
    
    func saveRecent() {
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
    
    func loadRecommended() async {
        guard let movie = recommendedMovie else { return }
        let similar = (try? await APIService.shared.similar(movieId: movie.id, mediaType: movie.mediaType)) ?? []
        await MainActor.run {
            recommendedMovies = similar
        }
    }
    
    func loadAnotherRecommend() async {
        let allMovies = vm.results.isEmpty ? vm.trending : vm.results
        guard !allMovies.isEmpty else { return }
        
        let otherMovies = allMovies.filter { $0.id != recommendedMovie?.id }
        if let newMovie = otherMovies.randomElement() {
            await MainActor.run {
                recommendedMovie = newMovie
            }
            await loadRecommended()
        }
    }
    
    func performSearch() async {
        if searchMode == .movies {
            await vm.search()
        } else {
            guard vm.query.count >= 2 else { actors = []; return }
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

// MARK: - Emmew Chat View
struct EmmewChatView: View {
    let movies: [Movie]
    @State private var messages: [(text: String, movies: [Movie], isUser: Bool)] = []
    @State private var input = ""
    @State private var isThinking = false
    @Environment(\.dismiss) var dismiss
    @FocusState private var chatFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                    .onTapGesture {
                        chatFocused = false
                    }
                
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(messages[index].text)
                                        .font(.system(size: 13))
                                        .foregroundColor(messages[index].isUser ? .black : .white)
                                        .padding(12)
                                        .background(messages[index].isUser ? .white : Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    
                                    if !messages[index].movies.isEmpty {
                                        VStack(spacing: 8) {
                                            ForEach(messages[index].movies.prefix(10)) { movie in
                                                HStack(spacing: 12) {
                                                    CachedAsyncImage(url: movie.posterURL)
                                                        .aspectRatio(2/3, contentMode: .fill)
                                                        .frame(width: 50, height: 75)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(movie.title)
                                                            .font(.system(size: 13, weight: .medium))
                                                            .foregroundColor(.white)
                                                            .lineLimit(2)
                                                        
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "star.fill")
                                                                .font(.system(size: 9))
                                                                .foregroundColor(.yellow)
                                                            Text(movie.ratingText)
                                                                .font(.system(size: 10))
                                                                .foregroundColor(.gray)
                                                            
                                                            Text("•")
                                                                .font(.system(size: 10))
                                                                .foregroundColor(.gray)
                                                            
                                                            Text(movie.yearText)
                                                                .font(.system(size: 10))
                                                                .foregroundColor(.gray)
                                                        }
                                                        
                                                        Text("FHD")
                                                            .font(.system(size: 8))
                                                            .foregroundColor(.yellow.opacity(0.7))
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Capsule().fill(.yellow.opacity(0.15)))
                                                    }
                                                    
                                                    Spacer()
                                                }
                                                .padding(8)
                                                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.05)))
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if isThinking {
                                HStack(spacing: 4) {
                                    Circle().fill(.gray).frame(width: 6, height: 6)
                                    Circle().fill(.gray.opacity(0.7)).frame(width: 6, height: 6)
                                    Circle().fill(.gray.opacity(0.4)).frame(width: 6, height: 6)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    
                    HStack(spacing: 8) {
                        TextField("Hỏi Emmew...", text: $input)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial.opacity(0.5)))
                            .focused($chatFocused)
                        
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Emmew AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    func sendMessage() {
        guard !input.isEmpty else { return }
        let question = input
        input = ""
        messages.append((text: question, movies: [], isUser: true))
        isThinking = true
        chatFocused = false
        
        Task {
            let aiResponse = await GeminiAPI.chat(question) ?? "Xin lỗi, Emmew chưa hiểu câu hỏi. Bạn thử hỏi lại nhé."
            
            let lowercased = question.lowercased()
            let movieId: Int
            let mediaType = "movie"
            
            if lowercased.contains("hành động") || lowercased.contains("action") {
                movieId = 98
            } else if lowercased.contains("tình cảm") || lowercased.contains("lãng mạn") || lowercased.contains("romance") {
                movieId = 194
            } else if lowercased.contains("kinh dị") || lowercased.contains("horror") {
                movieId = 274
            } else if lowercased.contains("hài") || lowercased.contains("comedy") {
                movieId = 350
            } else if lowercased.contains("hoạt hình") || lowercased.contains("anime") {
                movieId = 129
            } else if lowercased.contains("viễn tưởng") || lowercased.contains("sci-fi") {
                movieId = 157336
            } else {
                movieId = 162
            }
            
            let similar = (try? await APIService.shared.similar(movieId: movieId, mediaType: mediaType)) ?? movies
            await MainActor.run {
                messages.append((text: aiResponse, movies: similar, isUser: false))
                isThinking = false
            }
        }
    }
}

// MARK: - Gemini AI API
struct GeminiAPI {
    static let keyPart1 = "AQ.Ab8RN6K2QZ1urMD5W"
    static let keyPart2 = "TNCvkrWbi2NPS12e_isLUSkPdfHtj4dgA"
    static let apiKey = keyPart1 + keyPart2
    
    static func chat(_ message: String, context: String = "") async -> String? {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        
        var prompt = message
        if !context.isEmpty {
            prompt = "Bối cảnh: \(context)\n\nCâu hỏi: \(message)\n\nHãy trả lời tự nhiên như một trợ lý xem phim thân thiện tên Emmew. Trả lời ngắn gọn, hữu ích, không dùng emoji."
        } else {
            prompt = "Bạn là Emmew, trợ lý xem phim thân thiện. Hãy trả lời ngắn gọn, hữu ích, không dùng emoji.\n\nCâu hỏi: \(message)"
        }
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let content = first["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                return text
            }
        } catch {
            print("Gemini error: \(error)")
        }
        return nil
    }
}

// MARK: - Visual Effect Blur (UIKit bridge)
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// FlowLayout helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width + spacing > proposal.width ?? 320 {
                width = max(width, lineWidth)
                height += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        width = max(width, lineWidth)
        height += lineHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        
        for (i, subview) in subviews.enumerated() {
            if x + sizes[i].width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += sizes[i].width + spacing
            lineHeight = max(lineHeight, sizes[i].height)
        }
    }
}