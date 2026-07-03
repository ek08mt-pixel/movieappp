import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            // Nội dung chính
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    SearchView()
                case 2:
                    LibraryView()
                default:
                    HomeView()
                }
            }
            
            // Custom Floating Tab Bar
            HStack(spacing: 0) {
                TabItem(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
                
                TabItem(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
                
                TabItem(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
}

struct TabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
