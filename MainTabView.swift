import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView().opacity(selectedTab == 0 ? 1 : 0)
                ExploreView().opacity(selectedTab == 1 ? 1 : 0)
                LibraryView().opacity(selectedTab == 2 ? 1 : 0)
            }
            
            // Liquid Glass Tab Bar + Search riêng
            HStack(spacing: 0) {
                // Tab bar chính - 3 icon
                HStack(spacing: 32) {
                    LiquidTabIcon(icon: "house.fill", isSelected: selectedTab == 0) { selectedTab = 0 }
                    LiquidTabIcon(icon: "safari.fill", isSelected: selectedTab == 1) { selectedTab = 1 }
                    LiquidTabIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 2) { selectedTab = 2 }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(.clear)
                        .background(.ultraThinMaterial.opacity(0.3))
                        .blur(radius: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 100))
                .shadow(color: .white.opacity(0.03), radius: 2, y: -1)
                
                Spacer()
                
                // Nút Search riêng biệt - nổi bật hơn
                Button {
                    withAnimation(.interpolatingSpring(stiffness: 400, damping: 15)) {}
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.clear)
                                .background(.ultraThinMaterial.opacity(0.3))
                                .blur(radius: 0.5)
                        )
                        .clipShape(Circle())
                        .shadow(color: .white.opacity(0.05), radius: 4, y: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 22)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
    }
}

struct LiquidTabIcon: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 15)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.interpolatingSpring(stiffness: 400, damping: 15)) {
                    isPressed = false
                }
            }
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                .scaleEffect(isPressed ? 0.75 : 1.0)
                .shadow(color: isSelected ? .white.opacity(0.3) : .clear, radius: 6)
        }
    }
}