import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView().tag(0)
                Color.clear.tag(1)
                LibraryView().tag(2)
            }
            
            VStack {
                Spacer()
                HStack(spacing: 50) {
                    TabIcon(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedTab = 0 }
                    }
                    
                    TabIcon(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 2) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedTab = 2 }
                    }
                }
                .padding(.bottom, 20)
                
                .overlay {
                    Button {
                        showSearch = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 60, height: 60)
                                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                            
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .symbolEffect(.bounce.up.byLayer, value: showSearch)
                        }
                    }
                    .offset(y: -32)
                }
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
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
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                    .symbolEffect(.bounce.down.byLayer, value: isSelected)
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
        }
    }
}
