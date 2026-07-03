import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = "home"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Đảm bảo HomeView() được gọi đúng tên
            HomeView()
                .opacity(selectedTab == "home" ? 1 : 0)
            
            // TabBar của bạn ở đây
        }
    }
}
