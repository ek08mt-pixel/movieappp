import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                Color.clear.tag(1)
                LibraryView()
                    .tag(2)
            }
            
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    TabButton(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = 0 }
                    }
                    
                    Spacer().frame(width: 60)
                    
                    TabButton(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 2) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = 2 }
                    }
                }
                .frame(height: 56)
                .padding(.horizontal, 40)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 50)
                .padding(.bottom, 12)
                
                .overlay {
                    Button {
                        showSearch = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .offset(y: -34)
                }
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
    }
}

struct TabButton: View {
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
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
        }
        .frame(width: 50)
    }
}
