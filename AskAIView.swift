import SwiftUI

struct AskAIView: View {
    let movie: Movie
    @State private var question = ""
    @State private var chatHistory: [(String, String)] = []
    @State private var isLoading = false
    
    let sampleQuestions = ["Có plot twist không?", "Diễn viên chính là ai?", "Có phần 2 không?", "Phim này giống phim nào?", "Đáng xem không?"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 60, height: 90).clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading) { Text(movie.title).font(.headline).foregroundColor(.white); Text("⭐ \(movie.ratingText)").font(.caption).foregroundColor(.yellow) }
                            Spacer()
                        }.padding(.top)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(sampleQuestions, id: \.self) { q in
                                    Button { question = q; askAI(q) } label: {
                                        Text(q).font(.caption).foregroundColor(.white.opacity(0.8)).padding(10).background(Capsule().fill(.ultraThinMaterial))
                                    }
                                }
                            }
                        }
                        
                        ForEach(chatHistory, id: \.0) { q, a in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack { Image(systemName: "person.circle.fill").foregroundColor(.white.opacity(0.6)); Text("Bạn").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.6)); Spacer() }
                                Text(q).foregroundColor(.white).font(.subheadline).padding().background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                                HStack { Image(systemName: "sparkles").foregroundColor(.white.opacity(0.6)); Text("AI").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.6)); Spacer() }
                                Text(a).foregroundColor(.white).font(.subheadline).padding().background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
                            }
                        }
                        if isLoading { HStack { Spacer(); ProgressView().tint(.white); Spacer() } }
                        Spacer().frame(height: 80)
                    }.padding()
                }
                HStack(spacing: 8) {
                    TextField("Hỏi về phim này...", text: $question).textFieldStyle(.plain).foregroundColor(.white).padding(12).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                    Button { askAI(question) } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 32)).foregroundColor(.white.opacity(0.7)) }.disabled(question.isEmpty || isLoading)
                }.padding().padding(.bottom, 20)
            }
        }
    }
    
    func askAI(_ q: String) {
        guard !q.isEmpty else { return }
        isLoading = true; let userQ = q; question = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var answer = ""; let lowerQ = userQ.lowercased()
            if lowerQ.contains("plot twist") || lowerQ.contains("bất ngờ") { answer = "\(movie.title) có rating \(movie.ratingText)/10. Mình không muốn spoil, hãy xem và tự khám phá nhé! 🍿" }
            else if lowerQ.contains("diễn viên") || lowerQ.contains("actor") { answer = "Xem danh sách diễn viên đầy đủ ở phần 'Diễn viên' bên dưới trang chi tiết phim." }
            else if lowerQ.contains("phần 2") || lowerQ.contains("sequel") { answer = "Phim ra mắt năm \(movie.yearText). Hiện mình chưa có thông tin về phần tiếp theo." }
            else if lowerQ.contains("giống") || lowerQ.contains("tương tự") { answer = "Hãy xem phần 'Phim tương tự' bên dưới để tìm phim giống \(movie.title) nhé!" }
            else if lowerQ.contains("đáng xem") || lowerQ.contains("hay không") { answer = movie.voteAverage >= 7.0 ? "Có! \(movie.title) được đánh giá \(movie.ratingText)/10 - rất đáng xem!" : "\(movie.title) có rating \(movie.ratingText)/10. Bạn có thể xem trailer trước khi quyết định." }
            else { answer = "\(movie.title) (\(movie.yearText)) - Rating: \(movie.ratingText)/10. \(movie.overview.prefix(150))..." }
            chatHistory.append((userQ, answer)); isLoading = false
        }
    }
}