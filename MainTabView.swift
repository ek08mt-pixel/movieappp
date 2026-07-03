import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: String = "home"
    
    init() {
        // Ẩn thanh Tab Bar mặc định của hệ thống
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Lớp dưới: TabView ẩn để giữ trạng thái các View không bị load lại
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag("home")
                
                SearchView()
                    .tag("search")
                
                LibraryView()
                    .tag("library")
            }
            
            // Lớp trên: Floating Tab Bar tùy chỉnh
            HStack(spacing: 0) {
                TabButton(icon: "house.fill", title: "Home", tab: "home", selectedTab: $selectedTab)
                Spacer()
                TabButton(icon: "magnifyingglass", title: "Search", tab: "search", selectedTab: $selectedTab)
                Spacer()
                TabButton(icon: "square.grid.2x2.fill", title: "Library", tab: "library", selectedTab: $selectedTab)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 30)
            .background(
                RoundedRectangle(cornerRadius: 35)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 35)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5) // Viền cực mỏng
                    )
            )
            .padding(.horizontal, 25)
            .padding(.bottom, 25)
        }
    }
}

// Nút Tab tùy chỉnh
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
                .font(.system(size: 20))
                .foregroundColor(selectedTab == tab ? .white : .gray)
                .padding(10)
        }
    }
}
