import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Text("Home")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        }
    }
}
