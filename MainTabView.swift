import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: String = "home"
    
    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Lớp nội dung chính (Dùng ZStack + opacity để không bị load lại)
            ZStack {
                HomeView()
                    .opacity(selectedTab == "home" ? 1 : 0)
                
                SearchView()
                    .opacity(selectedTab == "search" ? 1 : 0)
                
                LibraryView()
                    .opacity(selectedTab == "library" ? 1 : 0)
            }
            .padding(.bottom, 90) // Đẩy nội dung lên cao để không bị che bởi tab bar

            // 2. Floating Tab Bar (Custom)
            HStack(spacing: 0) {
                Spacer()
                TabButton(icon: "house.fill", title: "Home", tab: "home", selectedTab: $selectedTab)
                Spacer()
                TabButton(icon: "magnifyingglass", title: "Search", tab: "search", selectedTab: $selectedTab)
                Spacer()
                TabButton(icon: "square.grid.2x2.fill", title: "Library", tab: "library", selectedTab: $selectedTab)
                Spacer()
            }
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Hiệu ứng mờ Telegram
                    Color.black.opacity(0.3)
                        .background(.ultraThinMaterial)
                    
                    // Viền mảnh tinh tế
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                }
            )
            .cornerRadius(30)
            .padding(.horizontal, 50) // Khoảng cách hai bên giúp tab bar mảnh hơn
            .padding(.bottom, 25) // Khoảng cách trôi nổi so với đáy
            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
        }
    }
}

// Nút bấm cho tab
struct TabButton: View {
    let icon: String
    let title: String
    let tab: String
    @Binding var selectedTab: String
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(selectedTab == tab ? .white : .gray.opacity(0.7))
                .padding(10)
        }
    }
}
