import SwiftUI

struct AskAIView: View {
    let movie: Movie
    @State private var question = ""
    @State private var answer = ""
    @State private var isLoading = false
    @State private var chatHistory: [(String, String)] = []
    let sampleQuestions = ["Có plot twist không?", "Diễn viên chính là ai?", "Có phần 2 không?", "Điểm IMDb bao nhiêu?", "Giống phim nào?"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack { CachedAsyncImage(url: movie.posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 60, height: 90).clipShape(RoundedRectangle(cornerRadius: 8)); VStack(alignment: .leading) { Text(movie.title).font(.headline).foregroundColor(.white); Text("⭐ \(movie.ratingText)").font(.caption).foregroundColor(.yellow) }; Spacer() }.padding(.top)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) { ForEach(sampleQuestions, id: \.self) { q in Button { question = q; askAI(q) } label: { Text(q).font(.caption).foregroundColor(.white).padding(10).background(Capsule().fill(.ultraThinMaterial)) } } }
                        }
                        ForEach(chatHistory, id: \.0) { q, a in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack { Image(systemName: "person.circle.fill").foregroundColor(.orange); Text("Bạn").font(.caption).fontWeight(.bold).foregroundColor(.orange); Spacer() }
                                Text(q).foregroundColor(.white).font(.subheadline).padding().background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                                HStack { Image(systemName: "brain.head.profile").foregroundColor(.purple); Text("AI").font(.caption).fontWeight(.bold).foregroundColor(.purple); Spacer() }
                                Text(a).foregroundColor(.white).font(.subheadline).padding().background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                            }
                        }
                        if isLoading { HStack { Spacer(); ProgressView().tint(.white); Spacer() } }
                    }.padding()
                }
                HStack(spacing: 8) { TextField("Hỏi về phim này...", text: $question).textFieldStyle(.plain).foregroundColor(.white).padding(12).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)); Button { askAI(question) } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 32)).foregroundColor(.orange) }.disabled(question.isEmpty || isLoading) }.padding()
            }
        }
    }
    
    func askAI(_ q: String) {
        guard !q.isEmpty else { return }
        isLoading = true; let userQ = q; question = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let responses = ["\(movie.title) là một bộ phim rất đáng xem! Rating \(movie.ratingText)/10.", "Phim ra mắt năm \(movie.yearText), thuộc thể loại rất hấp dẫn.", "Nội dung: \(movie.overview.prefix(100))...", "Mình nghĩ bạn sẽ thích phim này!", "Điểm IMDb: \(movie.ratingText) - Rất đáng để xem!"]
            chatHistory.append((userQ, responses.randomElement()!)); isLoading = false
        }
    }
}