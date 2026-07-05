import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Nội dung chính
            ZStack {
                HomeView().opacity(selectedTab == 0 ? 1 : 0)
                SearchView().opacity(selectedTab == 1 ? 1 : 0)
                ExploreView().opacity(selectedTab == 2 ? 1 : 0)
                LibraryView().opacity(selectedTab == 3 ? 1 : 0)
            }
            
            // Custom Tab Bar Glassmorphism
            HStack(spacing: 0) {
                CustomTabIcon(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 0 }
                }
                CustomTabIcon(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 1 }
                }
                CustomTabIcon(icon: "safari.fill", title: "Khám phá", isSelected: selectedTab == 2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 2 }
                }
                CustomTabIcon(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 3 }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Icon
struct CustomTabIcon: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = false
                }
            }
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                    .scaleEffect(isPressed ? 0.85 : 1.0)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}