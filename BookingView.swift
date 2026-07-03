import SwiftUI

struct BookingView: View {
    let movie: Movie
    
    var body: some View {
        List(movie.cinemas) { cinema in
            Button(action: {
                if let url = URL(string: cinema.bookingURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text(cinema.name)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Chọn Rạp")
        .background(Color.black)
    }
}
