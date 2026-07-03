import SwiftUI
import WebKit

struct MovieDetailView: View {
    let movie: Movie
    @StateObject private var vm = MovieDetailViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showTrailer = false
    @State private var showBookingSheet = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ... các thành phần giao diện khác ...
                    
                    Button { showBookingSheet = true } label: {
                        Label("Đặt vé", systemImage: "ticket.fill")
                            .frame(maxWidth: .infinity).padding(10)
                            .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    
                    // Phần phim tương tự
                    if !vm.similar.isEmpty {
                        Text("Phim tương tự").font(.headline).foregroundColor(.white).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(vm.similar.prefix(10)) { m in
                                    NavigationLink(destination: MovieDetailView(movie: m)) {
                                        VStack(alignment: .leading) {
                                            AsyncImage(url: m.posterURL) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: { Rectangle().fill(Color.gray.opacity(0.1)) }
                                            .frame(width: 120, height: 180).clipShape(RoundedRectangle(cornerRadius: 12))
                                            Text(m.title).font(.caption).foregroundColor(.white).lineLimit(1).frame(width: 120)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showBookingSheet) {
            BookingView(cinemas: movie.cinemas)
                .presentationDetents([.medium, .large])
        }
    }
}
