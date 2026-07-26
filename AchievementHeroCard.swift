import SwiftUI

struct AchievementHeroCard: View {
    // Màu sắc đặc thù cho Component này
    private let cardBgColor = Color(red: 0.12, green: 0.12, blue: 0.12) // #1E1E1E
    private let progressTint = Color.white
    private let progressBg = Color.white.opacity(0.15)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                // Phần Avatar Hexagon + Cat
                ZStack {
                    // Outer Glow Layer
                    HexagonShape()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .blur(radius: 12)
                        .frame(width: 100, height: 110)
                    
                    // Inner Base Layer (Tối)
                    HexagonShape()
                        .fill(
                            LinearGradient(
                                colors: [Color.black, Color(red: 0.15, green: 0.15, blue: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 110)
                    
                    // Border Stroke (Sáng hơn)
                    HexagonShape()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 100, height: 110)
                    
                    // Con mèo đen
                    ProCatShape()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                }
                .padding(.leading, 4)
                
                // Phần Text Info
                VStack(alignment: .leading, spacing: 6) {
                    // Level Badge
                    Text("Lv. 12")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                    
                    // Title
                    Text("Pro Watcher")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Subtitle
                    Text("Top 18% người xem tích cực")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Spacer().frame(height: 4)
                    
                    // Progress Bar & XP Text
                    VStack(alignment: .leading, spacing: 4) {
                        // Thanh trượt (Track + Fill)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(progressBg)
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(LinearGradient(colors: [Color.white, Color.white.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: 100, height: 4) // Giả lập % hoàn thành
                        }
                        
                        HStack(spacing: 0) {
                            Text("2,350 / 3,600 XP")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            Text("Còn 1,250 XP để lên cấp tiếp theo")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBgColor)
                // Thêm một viền siêu mờ để tạo cảm giác Card nổi
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.black
        AchievementHeroCard()
    }
}