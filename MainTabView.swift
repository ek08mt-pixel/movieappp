import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var homeID = UUID()
    @State private var dragOffset: CGFloat = 0
    @State private var exploreID = UUID()
    @State private var libraryID = UUID()
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    HomeView()
                        .id(homeID)
                        .frame(width: geo.size.width, height: geo.size.height)
                    ExploreView()
                        .id(exploreID)
                        .frame(width: geo.size.width, height: geo.size.height)
                    LibraryView()
                        .id(libraryID)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .offset(x: -CGFloat(selectedTab) * geo.size.width + dragOffset)
                .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: selectedTab)
                .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onChanged { value in
                            if selectedTab == 0 && value.translation.width > 0 { dragOffset = 0; return }
                            if selectedTab == 2 && value.translation.width < 0 { dragOffset = 0; return }
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold = geo.size.width * 0.25
                            if value.predictedEndTranslation.width > threshold && selectedTab > 0 {
                                selectedTab -= 1
                            } else if value.predictedEndTranslation.width < -threshold && selectedTab < 2 {
                                selectedTab += 1
                            }
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                dragOffset = 0
                            }
                        }
                )
            }
            .ignoresSafeArea()
            
            HStack(spacing: 12) {
                HStack(spacing: 44) {
                    LiquidTabIcon(icon: "house.fill", isSelected: selectedTab == 0) {
                        if selectedTab == 0 { homeID = UUID() }
                        else { withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { selectedTab = 0 } }
                    }
                    LiquidTabIcon(icon: "safari.fill", isSelected: selectedTab == 1) {
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { selectedTab = 1 }
                    }
                    LiquidTabIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 2) {
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { selectedTab = 2 }
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 32)
                .background(Capsule().fill(.ultraThinMaterial.opacity(0.2)).shadow(color: .black.opacity(0.08), radius: 4, y: 1))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 26, weight: .bold)).foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 14).padding(.horizontal, 20)
                        .background(Capsule().fill(.ultraThinMaterial.opacity(0.2)).shadow(color: .black.opacity(0.08), radius: 4, y: 1))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                }
            }
            .padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showSearch) { SearchView() }
    }
}

struct LiquidTabIcon: View {
    let icon: String; let isSelected: Bool; let action: () -> Void
    @State private var isPressed = false
    var body: some View {
        Button {
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 12)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.interpolatingSpring(stiffness: 400, damping: 12)) { isPressed = false } }
            action()
        } label: {
            ZStack {
                if isSelected { Capsule().fill(.ultraThinMaterial.opacity(0.35)).frame(width: 56, height: 38) }
                Image(systemName: icon).font(.system(size: 26, weight: isSelected ? .bold : .regular)).foregroundColor(isSelected ? .white : .white.opacity(0.45)).scaleEffect(isPressed ? 0.8 : 1.0)
            }
        }
    }
}