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
            
            HStack(spacing: 12) {
                // Khung 1: Home + Khám phá + Library
                HStack(spacing: 36) {
                    LiquidTabIcon(icon: "house.fill", isSelected: selectedTab == 0) { selectedTab = 0 }
                    LiquidTabIcon(icon: "safari.fill", isSelected: selectedTab == 1) { selectedTab = 1 }
                    LiquidTabIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 2) { selectedTab = 2 }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 28)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.25))
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                )
                .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
                
                // Khung 2: Search - Capsule tròn
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.25))
                                .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
                }
            }
            .padding(.bottom, 24)
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
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 12)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.interpolatingSpring(stiffness: 400, damping: 12)) {
                    isPressed = false
                }
            }
            action()
        } label: {
            ZStack {
                if isSelected {
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.4))
                        .frame(width: 56, height: 42)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.45))
                    .scaleEffect(isPressed ? 0.8 : 1.0)
            }
        }
    }
}