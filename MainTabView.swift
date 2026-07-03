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
            
            // 3 nút đơn, không nền, không khung
            HStack(spacing: 40) {
                TabButton(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                // Search
                Button {
                    showSearch = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Search")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                TabButton(icon: "square.grid.2x2.fill", title: "Library", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.bottom, 30)
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
    }
}
