import SwiftUI

struct AchievementHeroCard: View {
    @State private var progressAnimation: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                HexagonShape()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 90, height: 98)
                    .blur(radius: 16)
                
                HexagonShape()
                    .fill(LinearGradient(colors: [Color.cyan.opacity(0.2), Color(white: 0.05)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 88, height: 96)
                
                HexagonShape()
                    .stroke(LinearGradient(colors: [Color.cyan.opacity(0.8), Color.cyan.opacity(0.2), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                    .frame(width: 88, height: 96)
                
                CatShape()
                    .fill(Color.cyan)
                    .frame(width: 40, height: 40)
                
                Circle().fill(.white.opacity(0.8)).frame(width: 3, height: 3).offset(x: -40, y: -28)
                Circle().fill(.white.opacity(0.5)).frame(width: 2, height: 2).offset(x: 36, y: -26)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Lv. 12")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 0.5))
                
                Text("Pro Watcher")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Top 18% người xem")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                Spacer().frame(height: 2)
                
                VStack(alignment: .leading, spacing: 3) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 5)
                        Capsule()
                            .fill(LinearGradient(colors: [Color.cyan, Color.cyan.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 110 * progressAnimation, height: 5)
                    }
                    .onAppear { withAnimation(.easeOut(duration: 0.8)) { progressAnimation = 0.65 } }
                    
                    HStack {
                        Text("2,350 / 3,600 XP").font(.system(size: 10, design: .rounded)).foregroundColor(.gray)
                        Spacer()
                        Text("Còn 1,250 XP để lên Master").font(.system(size: 10, design: .rounded)).foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28).fill(Color(white: 0.1)))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(LinearGradient(colors: [Color.cyan.opacity(0.5), .white.opacity(0.15), Color.cyan.opacity(0.3), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.cyan.opacity(0.15), lineWidth: 4).blur(radius: 6))
        .shadow(color: Color.cyan.opacity(0.1), radius: 12, y: 6)
    }
}