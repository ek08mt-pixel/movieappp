import SwiftUI

// MARK: - MainTabView
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var homeID = UUID()
    @State private var exploreID = UUID()
    @State private var libraryID = UUID()
    @StateObject private var ostManager = OSTManager.shared
    
    init() { UITabBar.appearance().isHidden = true }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView().id(homeID).opacity(selectedTab == 0 ? 1 : 0)
                ExploreView().id(exploreID).opacity(selectedTab == 1 ? 1 : 0)
                LibraryView().id(libraryID).opacity(selectedTab == 2 ? 1 : 0)
            }
            
            // Dynamic Island
            if ostManager.isPlaying {
                VStack {
                    DynamicIslandView()
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: ostManager.isPlaying)
            }
            
            // Tab Bar
            HStack(spacing: 12) {
                HStack(spacing: 44) {
                    LiquidTabIcon(icon: "house.fill", isSelected: selectedTab == 0) {
                        if selectedTab == 0 { homeID = UUID() }
                        else { selectedTab = 0 }
                    }
                    LiquidTabIcon(icon: "safari.fill", isSelected: selectedTab == 1) {
                        if selectedTab == 1 { exploreID = UUID() }
                        else { selectedTab = 1 }
                    }
                    LiquidTabIcon(icon: "square.grid.2x2.fill", isSelected: selectedTab == 2) {
                        if selectedTab == 2 { libraryID = UUID() }
                        else { selectedTab = 2 }
                    }
                }
                .padding(.vertical, 14).padding(.horizontal, 32)
                .background(Capsule().fill(.ultraThinMaterial.opacity(0.2)).shadow(color: .black.opacity(0.08), radius: 4, y: 1))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass").font(.system(size: 26, weight: .bold)).foregroundColor(.white.opacity(0.8))
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

// MARK: - Dynamic Island View (iPhone 17-18 Pro Max style)
struct DynamicIslandView: View {
    @StateObject private var ostManager = OSTManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.ultraThinMaterial.opacity(0.5)))
                    
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ostManager.currentTrack)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(ostManager.currentMovie)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        ostManager.isPlaying = false
                        ostManager.currentTrack = ""
                        ostManager.currentMovie = ""
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(width: isExpanded ? 320 : 140, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05), .clear, .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Liquid Tab Icon
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