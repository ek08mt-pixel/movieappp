import SwiftUI

struct HomeView: View {
    @StateObject var vm = HomeViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack {
                    Text("Xu hướng").foregroundColor(.white).padding()
                    // Các nội dung khác
                }
            }
        }
        .task { await vm.loadMovies() }
    }
}
