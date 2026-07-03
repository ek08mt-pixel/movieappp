import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: String = "home"
    
    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Lớp nội dung: Sử dụng opacity để giữ trạng thái view (không load lại)
            ZStack {
                HomeView().opacity(selectedTab == "home" ? 1 : 0)
                SearchView().opacity(selectedTab == "search" ? 1 : 0)
                LibraryView().opacity(selectedTab == "library" ? 1 : 0)
            }
            .ignoresSafeArea(.all) // Cho phép nội dung tràn hết màn hình

            // Floating Tab Bar style Telegram
            HStack(spacing: 0) {
                Spacer()
                TabButton(icon: "house.fill", tab: "home", selectedTab: $selectedTab)
                Spacer()
                TabButton(icon: "magnifyingglass", tab: "search", selectedTab: $selectedTab)
                Spacer()
                TabButton(icon: "square.grid.2x2.fill", tab: "library", selectedTab: $selectedTab)
                Spacer()
            }
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // Hiệu ứng kính mờ
                    Color.black.opacity(0.2)
                        .background(.ultraThinMaterial)
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .padding(.horizontal, 70) // Thu hẹp ngang để thanh bar mảnh hơn
            .padding(.bottom, 25) // Khoảng cách trôi nổi so với đáy
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

struct TabButton: View {
    let icon: String
    let tab: String
    @Binding var selectedTab: String
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(selectedTab == tab ? .white : .gray.opacity(0.8))
                .padding(12)
        }
    }
}
