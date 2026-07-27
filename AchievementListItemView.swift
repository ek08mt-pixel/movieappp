import SwiftUI

struct AchievementListItemView: View {
    let item: AchievementItem
    @State private var isPressed = false
    
    var tierColor: Color {
        let colors: [Color] = [
            Color(red: 0.5, green: 0.5, blue: 0.55),
            Color(red: 0.6, green: 0.6, blue: 0.65),
            Color(red: 0.8, green: 0.7, blue: 0.3),
            Color(red: 0.0, green: 0.7, blue: 0.85),
            Color(red: 0.7, green: 0.3, blue: 0.8),
            Color(red: 1.0, green: 0.5, blue: 0.1),
            Color(red: 0.95, green: 0.2, blue: 0.2)
        ]
        return colors.randomElement() ?? .gray
    }
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tierColor.opacity(0.2), tierColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [tierColor.opacity(0.5), tierColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(tierColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(item.subtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                Text(item.date)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [tierColor.opacity(0.3), .white.opacity(0.06), tierColor.opacity(0.15), .white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(tierColor.opacity(0.08), lineWidth: 3)
                    .blur(radius: 3)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in isPressed = pressing }, perform: {})
    }
}