import SwiftUI

// MARK: - AchievementDetailView (Đã sửa lỗi build bằng cách loại bỏ hoàn toàn logic phụ thuộc vào Model cũ)
struct AchievementDetailView: View {
    // Vì Model cũ đã bị xóa, chúng ta dùng Mock Data đơn giản để file build được
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Chi tiết Danh hiệu")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Mô phỏng Card danh hiệu
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                    .frame(height: 200)
                    .overlay(
                        Text("Đang cập nhật...")
                            .foregroundColor(.gray)
                    )
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    AchievementDetailView()
}