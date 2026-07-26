import SwiftUI

// MARK: - Game-Style Shield Shape
struct GameShield: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addQuadCurve(to: CGPoint(x: w * 0.95, y: h * 0.15), control: CGPoint(x: w * 0.85, y: 0))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.8, y: h * 0.8))
        path.addQuadCurve(to: CGPoint(x: w * 0.1, y: h * 0.5), control: CGPoint(x: w * 0.2, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.15))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 0.15, y: 0))
        path.closeSubpath()
        return path
    }
}

struct EliteShield: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Main shield
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.55))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.75, y: h * 0.85))
        path.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.55), control: CGPoint(x: w * 0.25, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.18))
        path.closeSubpath()
        // Left wing
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.4))
        path.addQuadCurve(to: CGPoint(x: w * 0.02, y: h * 0.3), control: CGPoint(x: w * 0.05, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: w * 0.02, y: h * 0.55), control: CGPoint(x: w * 0.05, y: h * 0.45))
        path.addQuadCurve(to: CGPoint(x: w * 0.1, y: h * 0.48), control: CGPoint(x: w * 0.05, y: h * 0.5))
        // Right wing
        path.move(to: CGPoint(x: w * 0.9, y: h * 0.4))
        path.addQuadCurve(to: CGPoint(x: w * 0.98, y: h * 0.3), control: CGPoint(x: w * 0.95, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: w * 0.98, y: h * 0.55), control: CGPoint(x: w * 0.95, y: h * 0.45))
        path.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.48), control: CGPoint(x: w * 0.95, y: h * 0.5))
        return path
    }
}

struct WingedShield: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Main body
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.08))
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.2))
        path.addLine(to: CGPoint(x: w * 0.76, y: h * 0.55))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.95), control: CGPoint(x: w * 0.7, y: h * 0.8))
        path.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.55), control: CGPoint(x: w * 0.3, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.2))
        path.closeSubpath()
        // Left wing large
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.2), control: CGPoint(x: w * 0.05, y: h * 0.25))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.6), control: CGPoint(x: 0, y: h * 0.4))
        path.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.5), control: CGPoint(x: w * 0.05, y: h * 0.55))
        // Right wing large
        path.move(to: CGPoint(x: w * 0.85, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.2), control: CGPoint(x: w * 0.95, y: h * 0.25))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.6), control: CGPoint(x: w, y: h * 0.4))
        path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.5), control: CGPoint(x: w * 0.95, y: h * 0.55))
        return path
    }
}

// MARK: - Rank Badge View
struct RankBadgeView: View {
    let rank: Rank
    let size: CGFloat
    
    var shortCode: String {
        switch rank {
        case .newbie: return "N"
        case .explorer: return "E"
        case .movieFan: return "F"
        case .enthusiast: return "E+"
        case .proWatcher: return "P"
        case .master: return "M"
        case .legend: return "L"
        case .mythic: return "M+"
        }
    }
    
    var body: some View {
        ZStack {
            // Glow
            if rank != .newbie {
                GameShield()
                    .fill(rank.glowColor)
                    .frame(width: size, height: size * 1.1)
                    .blur(radius: size * 0.15)
            }
            
            // Shield body
            GameShield()
                .fill(
                    LinearGradient(
                        colors: [rank.color.opacity(0.2), rank.color.opacity(0.05), .black.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 1.1)
                .overlay(
                    GameShield()
                        .stroke(
                            LinearGradient(
                                colors: [rank.color.opacity(0.7), rank.color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: size * 0.03
                        )
                )
                .shadow(color: rank.glowColor, radius: size * 0.1)
            
            // Inner highlight
            GameShield()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    ),
                    lineWidth: size * 0.015
                )
                .frame(width: size * 0.85, height: size * 0.95)
            
            // Code
            Text(shortCode)
                .font(.system(size: size * 0.35, weight: .black, design: .monospaced))
                .foregroundColor(rank.color)
                .shadow(color: rank.color.opacity(0.5), radius: size * 0.05)
            
            // Crown for high ranks
            if [Rank.master, Rank.legend, Rank.mythic].contains(rank) {
                Text("✦")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundColor(rank.color)
                    .offset(y: -size * 0.5)
                    .shadow(color: rank.color.opacity(0.6), radius: size * 0.06)
            }
        }
        .frame(width: size, height: size * 1.15)
    }
}

// MARK: - Achievement Badge (small)
struct AchievementBadgeView2: View {
    let tier: Int
    let maxTier: Int
    let size: CGFloat
    
    var tierColor: Color {
        let ratio = Double(tier) / Double(max(maxTier, 1))
        return Color(red: 0.3 + 0.7 * ratio, green: 0.7 - 0.4 * ratio, blue: 0.9 - 0.3 * ratio)
    }
    
    var body: some View {
        ZStack {
            GameShield()
                .fill(
                    LinearGradient(
                        colors: [tierColor.opacity(0.2), tierColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 1.1)
                .overlay(
                    GameShield()
                        .stroke(
                            LinearGradient(
                                colors: [tierColor.opacity(0.5), tierColor.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: tierColor.opacity(0.15), radius: size * 0.1)
            
            Text("\(romanNumeral(tier))")
                .font(.system(size: size * 0.4, weight: .black, design: .monospaced))
                .foregroundColor(tierColor)
        }
        .frame(width: size, height: size * 1.1)
    }
    
    func romanNumeral(_ n: Int) -> String {
        let r = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        if n < r.count { return r[n] }
        return "\(n)"
    }
}