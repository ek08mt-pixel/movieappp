import SwiftUI

struct TimelineView: View {
    @State private var selectedYear = 2026
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    let years = Array(1900...2026).reversed()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").foregroundColor(.white).font(.system(size: 18, weight: .medium))
                    }
                    Spacer()
                    Text("Timeline").font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer().frame(width: 30)
                }.padding()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(years, id: \.self) { year in
                            Button {
                                selectedYear = year
                                loadMovies()
                            } label: {
                                Text("\(year)")
                                    .font(.system(size: 13, weight: selectedYear == year ? .bold : .regular))
                                    .foregroundColor(selectedYear == year ? .white : .gray)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(selectedYear == year ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))
                                    .clipShape(Capsule())
                            }
                        }
                    }.padding(.horizontal)
                }.padding(.bottom, 12)
                
                if isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if movies.isEmpty {
                    Spacer()
                    Text("Không có phim").foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 14) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    VStack(spacing: 6) {
                                        CachedAsyncImage(url: movie.posterURL)
                                            .aspectRatio(2/3, contentMode: .fill)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        Text(movie.title)
                                            .font(.system(size: 9, weight: .medium)).foregroundColor(.white).lineLimit(2)
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(.yellow)
                                            Text(movie.ratingText).font(.system(size: 8)).foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }.padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadMovies() }
    }
    
    func loadMovies() {
        isLoading = true
        Task {
            movies = (try? await APIService.shared.discoverMovies(year: selectedYear)) ?? []
            isLoading = false
        }
    }
}