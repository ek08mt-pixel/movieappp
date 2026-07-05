import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView().opacity(selectedTab == 0 ? 1 : 0)
                SearchView().opacity(selectedTab == 1 ? 1 : 0)
                ExploreView().opacity(selectedTab == 2 ? 1 : 0)
                LibraryView().opacity(selectedTab == 3 ? 1 : 0)
            }
            .ignoresSafeArea(edges: .bottom)
            
            // TabBar Glassmorphism
            HStack(spacing: 12) {
                TabIcon(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabIcon(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabIcon(icon: "safari.fill", title: "Khám phá", isSelected: selectedTab == 2) { selectedTab = 2 }
                TabIcon(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(.ultraThinMaterial)
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct TabIcon: View {
    let icon: String; let title: String; let isSelected: Bool; let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}