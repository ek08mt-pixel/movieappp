import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Tìm phim, diễn viên...", text: $vm.query)
                            .focused($isFocused)
                            .foregroundColor(.white)
                            .onSubmit { Task { await vm.search() } }
                        
                        if !vm.query.isEmpty {
                            Button {
                                vm.query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding()
                    
                    if vm.isSearching {
                        Spacer()
                        ProgressView().tint(.orange).scaleEffect(1.5)
                        Spacer()
                    } else if vm.results.isEmpty && !vm.query.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "film.stack").font(.system(size: 50)).foregroundColor(.gray)
                            Text("Không tìm thấy phim").foregroundColor(.gray)
                        }
                        Spacer()
                    } else if !vm.results.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(vm.results) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        MovieRow(movie: movie)
                                            .padding(.horizontal)
                                            .padding(.vertical, 6)
                                    }
                                    Divider().background(Color.gray.opacity(0.3)).padding(.horizontal)
                                }
                            }
                        }
                    } else {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "popcorn.fill").font(.system(size: 60)).foregroundColor(.orange)
                            Text("Bạn muốn xem gì hôm nay?").foregroundColor(.gray).font(.headline)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Tìm kiếm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        // dismiss
                    }
                }
            }
        }
        .onAppear { isFocused = true }
    }
}
