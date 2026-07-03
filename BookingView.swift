import SwiftUI

struct BookingView: View {
    let cinemas: [Cinema]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if cinemas.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "ticket")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Chưa có thông tin rạp")
                            .foregroundColor(.white)
                    }
                } else {
                    List(cinemas) { cinema in
                        Button(action: {
                            if let url = URL(string: cinema.bookingURL) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Text(cinema.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.gray.opacity(0.1))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Chọn Rạp")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(.blue)
                }
            }
            .background(Color.black)
        }
        .onAppear {
            print("BookingView đã nhận được \(cinemas.count) rạp.")
        }
    }
}
