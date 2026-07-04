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
                                        Text(q).font(.caption).foregroundColor(.white).padding(10).background(Capsule().fill(.ultraThinMaterial))
                                    }
                                }
                            }
                        }
                        
                        ForEach(chatHistory, id: \.0) { q, a in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack { Image(systemName: "person.circle.fill").foregroundColor(.orange); Text("Bạn").font(.caption).fontWeight(.bold).foregroundColor(.orange); Spacer() }
                                Text(q).foregroundColor(.white).font(.subheadline).padding().background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                                HStack { Image(systemName: "sparkles").foregroundColor(.purple); Text("AI").font(.caption).fontWeight(.bold).foregroundColor(.purple); Spacer() }
                                Text(a).foregroundColor(.white).font(.subheadline).padding().background(RoundedRectangle(cornerRadius: 12).fill(.purple.opacity(0.15)))
                            }
                        }
                        if isLoading { HStack { Spacer(); ProgressView().tint(.white); Spacer() } }
                    }.padding()
                }
                HStack(spacing: 8) {
                    TextField("Hỏi về phim này...", text: $question).textFieldStyle(.plain).foregroundColor(.white).padding(12).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                    Button { askAI(question) } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 32)).foregroundColor(.orange) }.disabled(question.isEmpty || isLoading)
                }.padding()
            }
        }
    }
    
    func askAI(_ q: String) {
        guard !q.isEmpty else { return }
        isLoading = true; let userQ = q; question = ""
        
        // Dùng kiến thức có sẵn về phim để trả lời thông minh hơn
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var answer = ""
            let lowerQ = userQ.lowercased()
            
            if lowerQ.contains("plot twist") || lowerQ.contains("bất ngờ") {
                answer = "\(movie.title) có rating \(movie.ratingText)/10. Dựa trên điểm số này, phim có thể có những tình tiết hấp dẫn. Tuy nhiên mình không muốn spoil trước, hãy xem và tự khám phá nhé! 🍿"
            } else if lowerQ.contains("diễn viên") || lowerQ.contains("actor") {
                answer = "\(movie.title) có sự tham gia của dàn diễn viên tài năng. Bạn có thể xem danh sách đầy đủ ở phần 'Diễn viên' bên dưới trang chi tiết phim."
            } else if lowerQ.contains("phần 2") || lowerQ.contains("sequel") {
                answer = "Hiện tại mình chưa có thông tin về phần tiếp theo của \(movie.title). Phim ra mắt năm \(movie.yearText), bạn có thể kiểm tra thêm trên Google."
            } else if lowerQ.contains("giống") || lowerQ.contains("tương tự") {
                answer = "Nếu bạn thích \(movie.title), hãy xem phần 'Phim tương tự' bên dưới. Mình cũng recommend bạn xem thêm các phim cùng thể loại!"
            } else if lowerQ.contains("đáng xem") || lowerQ.contains("hay không") {
                answer = movie.voteAverage >= 7.0 ? "Có! \(movie.title) được đánh giá \(movie.ratingText)/10 - rất đáng xem! 👍" : "\(movie.title) có rating \(movie.ratingText)/10. Tùy gu mỗi người, nhưng bạn có thể thử xem trailer trước khi quyết định."
            } else {
                answer = "\(movie.title) (\(movie.yearText)) - Rating: \(movie.ratingText)/10. \(movie.overview.prefix(150))... Bạn có thể xem trailer hoặc xem phim để biết thêm chi tiết!"
            }
            
            chatHistory.append((userQ, answer))
            isLoading = false
        }
    }
}