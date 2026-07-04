import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView().opacity(selectedTab == 0 ? 1 : 0)
                SearchView().opacity(selectedTab == 1 ? 1 : 0)
                LibraryView().opacity(selectedTab == 2 ? 1 : 0)
            }
            
            HStack {
                Spacer()
                TabButton(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
                Spacer()
                TabButton(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 1) { selectedTab = 1 }
                Spacer()
                TabButton(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 2) { selectedTab = 2 }
                Spacer()
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.black.opacity(0.8))
                    .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 3)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                Text(title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
