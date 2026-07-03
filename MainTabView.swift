import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView().tag(0)
                Color.clear.tag(1)
                LibraryView().tag(2)
            }
            
            // Thanh tab kiểu Telegram/iOS 27 - mỏng, tràn đáy, không khung
            HStack(spacing: 0) {
                Spacer()
                TabButton(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                Spacer()
                Spacer()
                Spacer()
                TabButton(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                Spacer()
            }
            .padding(.bottom, 25)
            .padding(.top, 10)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
            
            // Nút Search nổi
            Button {
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    )
            }
            .offset(y: -28)
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
                    .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.5))
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
