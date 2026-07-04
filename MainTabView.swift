import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView().tag(0)
                SearchView().tag(1)
                ExploreView().tag(2)
                LibraryView().tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            HStack(spacing: 0) {
                TabIcon(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedTab = 0 } }
                TabIcon(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 1) { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedTab = 1 } }
                TabIcon(icon: "safari.fill", title: "Khám phá", isSelected: selectedTab == 2) { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedTab = 2 } }
                TabIcon(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 3) { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedTab = 3 } }
            }
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 40).fill(Color.black.opacity(0.8)).background(.ultraThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 40)).shadow(color: .black.opacity(0.3), radius: 10, y: 3)
            .padding(.horizontal, 16).padding(.bottom, 30)
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
        .animation(.spring(response: 0.3), value: isSelected)
    }
}