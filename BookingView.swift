import SwiftUI

struct BookingView: View {
    let cinemas: [Cinema]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(cinemas) { cinema in
                Button(action: {
                    if let url = URL(string: cinema.bookingURL) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text(cinema.name)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Chọn Rạp")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .background(Color.black)
            .scrollContentBackground(.hidden)
        }
    }
}
