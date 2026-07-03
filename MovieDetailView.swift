// ... (Giữ nguyên phần đầu file đến hết phần nút Trailer)

                            if showBooking {
                                Button {
                                    showBookingSheet = true
                                } label: {
                                    Label("Đặt vé", systemImage: "ticket.fill")
                                        .frame(maxWidth: .infinity).padding(10)
                                        .background(.ultraThinMaterial).foregroundColor(.white).clipShape(Capsule())
                                        .font(.caption).fontWeight(.bold)
                                }
                            }

// ... (Giữ nguyên phần nút Lưu và phần hiển thị Diễn viên, Phim tương tự)

        // Dán phần này thay cho cái sheet cũ của bạn:
        .sheet(isPresented: $showBookingSheet) {
            BookingView(cinemas: movie.cinemas)
                .presentationDetents([.medium, .large])
        }
    }
}
