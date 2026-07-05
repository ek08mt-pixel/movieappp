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
            
            HStack(spacing: 16) {
                TabIcon(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabIcon(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabIcon(icon: "safari.fill", title: "Khám phá", isSelected: selectedTab == 2) { selectedTab = 2 }
                TabIcon(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 3)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct TabIcon: View {
    let icon: String; let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}