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
                    Button {
                        selectedTab = 0
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 22, weight: selectedTab == 0 ? .bold : .regular))
                            Text("Home")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(selectedTab == 0 ? .white : .gray.opacity(0.5))
                    }
                    
                    Button {
                        showSearch = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 22, weight: .bold))
                            Text("Search")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Button {
                        selectedTab = 2
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 22, weight: selectedTab == 2 ? .bold : .regular))
                            Text("Library")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(selectedTab == 2 ? .white : .gray.opacity(0.5))
                    }
                }
                .padding(.bottom, 35)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
    }
}
