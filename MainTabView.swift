import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: String = "home"
    
    init() {
        // Ẩn thanh Tab Bar hệ thống để thay thế bằng custom bar
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Lớp nội dung: Sử dụng ZStack để chứa các view, 
            // dùng opacity để ẩn/hiện giúp giữ trạng thái (không bị load lại)
            ZStack {
                HomeView().opacity(selectedTab == "home" ? 1 : 0)
                SearchView().opacity(selectedTab == "search" ? 1 : 0)
                LibraryView().opacity(selectedTab == "library" ? 1 : 0)
            }
            .padding(.bottom, 80) // Đẩy nội dung lên để không bị Tab Bar che

            // Floating Tab Bar
            HStack {
                TabButton(icon: "house.fill", tab: "home", selectedTab: $selectedTab)
                Spacer()
                TabButton(icon: "magnifyingglass", tab: "search", selectedTab: $selectedTab)
                Spacer()
                TabButton(icon: "square.grid.2x2.fill", tab: "library", selectedTab: $selectedTab)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 40)
            .background(
                Capsule() // Dùng hình con nhộng cho Telegram style
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 30)
            .padding(.bottom, 20) // Khoảng cách trôi nổi so với đáy
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
                .font(.system(size: 22))
                .foregroundColor(selectedTab == tab ? .white : .gray)
        }
    }
}
