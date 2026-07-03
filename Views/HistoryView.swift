import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if appState.watchHistory.isEmpty && appState.searchHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Chưa có lịch sử")
                            .foregroundColor(.gray)
                            .font(.headline)
                    }
                } else {
                    List {
                        if !appState.watchHistory.isEmpty {
                            Section("Đã xem trailer") {
                                ForEach(appState.watchHistory) { movie in
                                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                                        MovieRow(movie: movie)
                                    }
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        
                        if !appState.searchHistory.isEmpty {
                            Section("Tìm kiếm gần đây") {
                                ForEach(appState.searchHistory, id: \.self) { term in
                                    HStack {
                                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                                        Text(term).foregroundColor(.white)
                                    }
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Lịch sử")
        }
    }
}
