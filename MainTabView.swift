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
                AIRecommendView().opacity(selectedTab == 3 ? 1 : 0)
                LibraryView().opacity(selectedTab == 4 ? 1 : 0)
            }
            .ignoresSafeArea(edges: .bottom)
            
            HStack(spacing: 0) {
                TabIcon(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabIcon(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabIcon(icon: "safari.fill", title: "Khám phá", isSelected: selectedTab == 2) { selectedTab = 2 }
                TabIcon(icon: "brain.head.profile", title: "AI", isSelected: selectedTab == 3) { selectedTab = 3 }
                TabIcon(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 4) { selectedTab = 4 }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 10, y: 3)
            .padding(.horizontal, 16)
            .padding(.bottom, 25)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct TabIcon: View {
    let icon: String; let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 20, weight: isSelected ? .bold : .regular)).foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                Text(title).font(.system(size: 9, weight: isSelected ? .semibold : .regular)).foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}