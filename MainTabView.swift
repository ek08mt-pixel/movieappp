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
            .tabViewStyle(.automatic)
            
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
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                )
                .padding(.horizontal, 50)
                .padding(.bottom, 12)
                
                // Search button nổi
                .overlay {
                    Button {
                        showSearch = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .pink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 64, height: 64)
                                .shadow(color: .orange.opacity(0.6), radius: 16, y: -4)
                            
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
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
                    .foregroundColor(isSelected ? .orange : .gray.opacity(0.6))
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .orange : .gray.opacity(0.6))
            }
        }
        .frame(width: 50)
    }
}
