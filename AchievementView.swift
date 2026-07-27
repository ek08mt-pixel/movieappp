import SwiftUI

struct AchievementView: View {
    @StateObject private var viewModel = AchievementManager()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = "Tổng quan"
    private let tabs = ["Tổng quan", "Cày Phim", "Thể Loại", "Liên Tục", "Hiếm"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Text("←")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(white: 0.15)))
                        }
                        Spacer()
                        Text("Danh hiệu")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 20)
                    
                    // Hero card đơn giản
                    AchievementHeroCard()
                        .padding(.horizontal, 20)
                    
                    // Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tabs, id: \.self) { tab in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedTab = tab
                                    }
                                }) {
                                    Text(tab)
                                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                                        .foregroundColor(selectedTab == tab ? .white : .gray)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedTab == tab ? .white.opacity(0.15) : .white.opacity(0.05))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Achievement list
                    VStack(spacing: 10) {
                        ForEach(viewModel.achievements) { item in
                            AchievementListItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}