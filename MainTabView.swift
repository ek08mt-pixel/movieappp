import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: SearchView()
                case 2: LibraryView()
                default: HomeView()
                }
            }
            
            // Thanh Tab mỏng, trôi nổi, giống Telegram
            HStack(spacing: 0) {
                TabIcon(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
                
                TabIcon(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 1) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
                
                TabIcon(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 2) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.black.opacity(0.7))
                    .background(.ultraThinMaterial)
                    .blur(radius: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
            .padding(.horizontal, 60)
            .padding(.bottom, 28)
        }
    }
}

struct TabIcon: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                Text(title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
