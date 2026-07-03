import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showSearch = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                HistoryView()
                    .tag(1)
                
                Color.clear
                    .tag(2)
                
                ProfileView()
                    .tag(3)
            }
            .tabViewStyle(.automatic)
            
            // Custom Tab Bar
            HStack(spacing: 0) {
                // Home
                TabButton(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                // History
                TabButton(icon: "clock.fill", title: "Lịch sử", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                // Search (Nổi lên)
                Button {
                    showSearch = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: -2)
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -18)
                
                // Profile
                TabButton(icon: "person.fill", title: "Chung", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
            .frame(height: 70)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
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
                Image(systemName: isSelected ? icon : icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .orange : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .orange : .gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
