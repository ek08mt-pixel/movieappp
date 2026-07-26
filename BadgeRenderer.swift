import SwiftUI

// MARK: - Badge Shape Types
struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.55))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.85, y: h * 0.85))
        path.addQuadCurve(to: CGPoint(x: w * 0.05, y: h * 0.55), control: CGPoint(x: w * 0.15, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.1))
        path.closeSubpath()
        return path
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let s: CGFloat = 0.15
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w * (1 - s), y: h * 0.25))
        path.addLine(to: CGPoint(x: w * (1 - s), y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        path.addLine(to: CGPoint(x: w * s, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * s, y: h * 0.25))
        path.closeSubpath()
        return path
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.3))
        path.closeSubpath()
        return path
    }
}

struct WingedShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Left wing
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.15), control: CGPoint(x: w * 0.1, y: h * 0.3))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.6), control: CGPoint(x: w * 0.05, y: h * 0.4))
        path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.35), control: CGPoint(x: w * 0.1, y: h * 0.5))
        
        // Center shield
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.6))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.95), control: CGPoint(x: w * 0.75, y: h * 0.8))
        path.addQuadCurve(to: CGPoint(x: w * 0.2, y: h * 0.6), control: CGPoint(x: w * 0.25, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.15))
        path.closeSubpath()
        
        // Right wing
        path.move(to: CGPoint(x: w * 0.65, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.15), control: CGPoint(x: w * 0.9, y: h * 0.3))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.6), control: CGPoint(x: w * 0.95, y: h * 0.4))
        path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.5), control: CGPoint(x: w * 0.9, y: h * 0.5))
        
        return path
    }
}

struct SeraphimShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.5
        let cy = h * 0.5
        let r: CGFloat = min(w, h) * 0.45
        let wings: Int = 6
        
        for i in 0..<wings {
            let angle = Double(i) / Double(wings) * 2 * .pi - .pi / 2
            let wingAngle: Double = .pi / Double(wings)
            let x1 = cx + r * cos(angle - wingAngle)
            let y1 = cy + r * sin(angle - wingAngle)
            let x2 = cx + r * 1.6 * cos(angle)
            let y2 = cy + r * 1.6 * sin(angle)
            let x3 = cx + r * cos(angle + wingAngle)
            let y3 = cy + r * sin(angle + wingAngle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x1, y: y1))
            } else {
                path.addLine(to: CGPoint(x: x1, y: y1))
            }
            path.addQuadCurve(to: CGPoint(x: x3, y: y3), control: CGPoint(x: x2, y: y2))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Cat Face Drawing Components
struct CatFaceSimple: View {
    var body: some View {
        ZStack {
            // Face circle
            Circle()
                .fill(Color(white: 0.25))
                .frame(width: 36, height: 36)
            
            // Ears
            Path { path in
                path.move(to: CGPoint(x: -10, y: -14))
                path.addLine(to: CGPoint(x: -5, y: -2))
                path.addLine(to: CGPoint(x: -16, y: 0))
                path.closeSubpath()
                path.move(to: CGPoint(x: 10, y: -14))
                path.addLine(to: CGPoint(x: 5, y: -2))
                path.addLine(to: CGPoint(x: 16, y: 0))
                path.closeSubpath()
            }
            .fill(Color(white: 0.25))
            
            // Eyes
            Circle().fill(Color(white: 0.7)).frame(width: 5, height: 5).offset(x: -7, y: -3)
            Circle().fill(Color(white: 0.7)).frame(width: 5, height: 5).offset(x: 7, y: -3)
            Circle().fill(.black).frame(width: 2.5, height: 2.5).offset(x: -7, y: -3)
            Circle().fill(.black).frame(width: 2.5, height: 2.5).offset(x: 7, y: -3)
            
            // Nose
            Path { path in
                path.move(to: CGPoint(x: 0, y: 2))
                path.addLine(to: CGPoint(x: -3, y: 6))
                path.addLine(to: CGPoint(x: 3, y: 6))
                path.closeSubpath()
            }
            .fill(Color(white: 0.5))
            
            // Whiskers
            Path { path in
                path.move(to: CGPoint(x: -12, y: 2))
                path.addLine(to: CGPoint(x: -4, y: 4))
                path.move(to: CGPoint(x: -12, y: 6))
                path.addLine(to: CGPoint(x: -4, y: 5))
                path.move(to: CGPoint(x: 12, y: 2))
                path.addLine(to: CGPoint(x: 4, y: 4))
                path.move(to: CGPoint(x: 12, y: 6))
                path.addLine(to: CGPoint(x: 4, y: 5))
            }
            .stroke(Color(white: 0.5), lineWidth: 0.5)
        }
    }
}

struct CatFaceCool: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.2))
                .frame(width: 36, height: 36)
            
            // Ears
            Path { path in
                path.move(to: CGPoint(x: -10, y: -14))
                path.addLine(to: CGPoint(x: -5, y: -2))
                path.addLine(to: CGPoint(x: -16, y: 0))
                path.closeSubpath()
                path.move(to: CGPoint(x: 10, y: -14))
                path.addLine(to: CGPoint(x: 5, y: -2))
                path.addLine(to: CGPoint(x: 16, y: 0))
                path.closeSubpath()
            }
            .fill(Color(white: 0.2))
            
            // Sunglasses
            RoundedRectangle(cornerRadius: 3)
                .fill(.black)
                .frame(width: 22, height: 8)
                .offset(y: -3)
            RoundedRectangle(cornerRadius: 1)
                .fill(.black)
                .frame(width: 4, height: 2)
                .offset(x: 0, y: -3)
            
            // Nose & smirk
            Path { path in
                path.move(to: CGPoint(x: 0, y: 3))
                path.addLine(to: CGPoint(x: -2, y: 6))
                path.addLine(to: CGPoint(x: 3, y: 5))
            }
            .stroke(Color(white: 0.5), lineWidth: 1)
            
            // Whiskers
            Path { path in
                path.move(to: CGPoint(x: -11, y: 1))
                path.addLine(to: CGPoint(x: -4, y: 3))
                path.move(to: CGPoint(x: -11, y: 5))
                path.addLine(to: CGPoint(x: -4, y: 4.5))
                path.move(to: CGPoint(x: 11, y: 1))
                path.addLine(to: CGPoint(x: 4, y: 3))
                path.move(to: CGPoint(x: 11, y: 5))
                path.addLine(to: CGPoint(x: 4, y: 4.5))
            }
            .stroke(Color(white: 0.5), lineWidth: 0.5)
        }
    }
}

struct CatFacePro: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 36, height: 36)
            
            // Pointed ears
            Path { path in
                path.move(to: CGPoint(x: -12, y: -15))
                path.addLine(to: CGPoint(x: -6, y: -3))
                path.addLine(to: CGPoint(x: -17, y: 1))
                path.closeSubpath()
                path.move(to: CGPoint(x: 12, y: -15))
                path.addLine(to: CGPoint(x: 6, y: -3))
                path.addLine(to: CGPoint(x: 17, y: 1))
                path.closeSubpath()
            }
            .fill(Color(white: 0.15))
            
            // Aviator sunglasses
            Path { path in
                path.move(to: CGPoint(x: -10, y: -2))
                path.addQuadCurve(to: CGPoint(x: 10, y: -2), control: CGPoint(x: 0, y: -6))
                path.addLine(to: CGPoint(x: 12, y: 2))
                path.addQuadCurve(to: CGPoint(x: -12, y: 2), control: CGPoint(x: 0, y: 5))
                path.closeSubpath()
            }
            .fill(.black.opacity(0.9))
            .frame(width: 26, height: 10)
            .offset(y: -3)
            
            // Cool smirk
            Path { path in
                path.move(to: CGPoint(x: -3, y: 5))
                path.addQuadCurve(to: CGPoint(x: 6, y: 4), control: CGPoint(x: 2, y: 7))
            }
            .stroke(Color(white: 0.5), lineWidth: 1)
        }
    }
}

struct CatFaceCrown: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.12))
                .frame(width: 36, height: 36)
            
            // Sharp ears
            Path { path in
                path.move(to: CGPoint(x: -11, y: -15))
                path.addLine(to: CGPoint(x: -6, y: -2))
                path.addLine(to: CGPoint(x: -16, y: 2))
                path.closeSubpath()
                path.move(to: CGPoint(x: 11, y: -15))
                path.addLine(to: CGPoint(x: 6, y: -2))
                path.addLine(to: CGPoint(x: 16, y: 2))
                path.closeSubpath()
            }
            .fill(Color(white: 0.12))
            
            // Crown
            Path { path in
                path.move(to: CGPoint(x: -10, y: -18))
                path.addLine(to: CGPoint(x: -6, y: -10))
                path.addLine(to: CGPoint(x: -2, y: -14))
                path.addLine(to: CGPoint(x: 2, y: -10))
                path.addLine(to: CGPoint(x: 6, y: -14))
                path.addLine(to: CGPoint(x: 10, y: -10))
                path.addLine(to: CGPoint(x: 12, y: -18))
                path.addLine(to: CGPoint(x: -10, y: -18))
            }
            .fill(Color(white: 0.5))
            
            // Eyes
            Circle().fill(Color(white: 0.8)).frame(width: 4, height: 4).offset(x: -6, y: -2)
            Circle().fill(Color(white: 0.8)).frame(width: 4, height: 4).offset(x: 6, y: -2)
            Circle().fill(.black).frame(width: 2, height: 2).offset(x: -6, y: -2)
            Circle().fill(.black).frame(width: 2, height: 2).offset(x: 6, y: -2)
            
            // Noble expression
            Path { path in
                path.move(to: CGPoint(x: -2, y: 5))
                path.addLine(to: CGPoint(x: 0, y: 7))
                path.addLine(to: CGPoint(x: 2, y: 5))
            }
            .stroke(Color(white: 0.5), lineWidth: 1)
        }
    }
}

struct CatFaceLegend: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: 36, height: 36)
            
            // Glowing aura lines
            ForEach(0..<8) { i in
                let angle = Double(i) * .pi / 4
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 20 * cos(angle), y: 20 * sin(angle)))
                }
                .stroke(Color(white: 0.3), lineWidth: 0.3)
            }
            
            // Cat base
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: 30, height: 30)
            
            // Glowing eyes
            Circle().fill(.white).frame(width: 5, height: 5).offset(x: -5, y: -2)
            Circle().fill(.white).frame(width: 5, height: 5).offset(x: 5, y: -2)
            Circle().fill(.white).frame(width: 7, height: 7).offset(x: -5, y: -2).opacity(0.3)
            Circle().fill(.white).frame(width: 7, height: 7).offset(x: 5, y: -2).opacity(0.3)
            
            // Majestic whiskers
            ForEach([-1.0, 0, 1.0] as [Double], id: \.self) { dy in
                Path { path in
                    path.move(to: CGPoint(x: -15, y: dy))
                    path.addLine(to: CGPoint(x: -5, y: 3 + dy * 0.5))
                    path.move(to: CGPoint(x: 15, y: dy))
                    path.addLine(to: CGPoint(x: 5, y: 3 + dy * 0.5))
                }
                .stroke(Color(white: 0.4), lineWidth: 0.4)
            }
        }
    }
}

struct CatFaceMythic: View {
    var body: some View {
        ZStack {
            // Dragon-like horns
            Path { path in
                path.move(to: CGPoint(x: -12, y: -10))
                path.addQuadCurve(to: CGPoint(x: -8, y: -22), control: CGPoint(x: -16, y: -16))
                path.addQuadCurve(to: CGPoint(x: -3, y: -8), control: CGPoint(x: -4, y: -16))
                path.move(to: CGPoint(x: 12, y: -10))
                path.addQuadCurve(to: CGPoint(x: 8, y: -22), control: CGPoint(x: 16, y: -16))
                path.addQuadCurve(to: CGPoint(x: 3, y: -8), control: CGPoint(x: 4, y: -16))
            }
            .fill(Color(white: 0.1))
            
            Circle()
                .fill(Color(white: 0.05))
                .frame(width: 36, height: 36)
            
            // Dragon scales pattern
            ForEach(0..<6) { i in
                let angle = Double(i) * .pi / 3
                Circle()
                    .fill(Color(white: 0.1))
                    .frame(width: 4, height: 4)
                    .offset(x: 10 * cos(angle), y: 10 * sin(angle))
            }
            
            // Fiery eyes
            Circle().fill(.white).frame(width: 5, height: 5).offset(x: -5, y: -2)
            Circle().fill(.white).frame(width: 5, height: 5).offset(x: 5, y: -2)
            Circle().fill(Color.red.opacity(0.6)).frame(width: 3, height: 3).offset(x: -5, y: -2)
            Circle().fill(Color.red.opacity(0.6)).frame(width: 3, height: 3).offset(x: 5, y: -2)
        }
    }
}

// MARK: - Cat Badge Renderer
struct CatBadgeView: View {
    let rank: Rank
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Glow
            if rank != .newbie {
                Circle()
                    .fill(rank.glowColor)
                    .frame(width: size * 0.8, height: size * 0.8)
                    .blur(radius: size * 0.2)
            }
            
            // Badge shape + cat
            badgeContent
        }
        .frame(width: size, height: size * 1.1)
    }
    
    @ViewBuilder
    var badgeContent: some View {
        switch rank {
        case .newbie:
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [rank.color.opacity(0.12), rank.color.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().stroke(LinearGradient(colors: [rank.color.opacity(0.5), rank.color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.025))
                    .shadow(color: rank.glowColor, radius: size * 0.12)
                CatFaceSimple()
            }
            .frame(width: size, height: size)
        case .explorer:
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [rank.color.opacity(0.12), rank.color.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().stroke(LinearGradient(colors: [rank.color.opacity(0.5), rank.color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.025))
                    .shadow(color: rank.glowColor, radius: size * 0.12)
                CatFaceSimple()
            }
            .frame(width: size, height: size)
        case .movieFan:
            ZStack {
                HexagonShape()
                    .fill(LinearGradient(colors: [rank.color.opacity(0.12), rank.color.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(HexagonShape().stroke(LinearGradient(colors: [rank.color.opacity(0.5), rank.color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.025))
                    .shadow(color: rank.glowColor, radius: size * 0.12)
                CatFaceCool()
            }
            .frame(width: size, height: size)
        case .enthusiast:
            ZStack {
                DiamondShape()
                    .fill(LinearGradient(colors: [rank.color.opacity(0.12), rank.color.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(DiamondShape().stroke(LinearGradient(colors: [rank.color.opacity(0.5), rank.color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.025))
                    .shadow(color: rank.glowColor, radius: size * 0.12)
                CatFaceCool()
            }
            .frame(width: size, height: size)
        case .proWatcher:
            ZStack {
                ShieldShape()
                    .fill(LinearGradient(colors: [rank.color.opacity(0.12), rank.color.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(ShieldShape().stroke(LinearGradient(colors: [rank.color.opacity(0.5), rank.color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.025))
                    .shadow(color: rank.glowColor, radius: size * 0.12)
                CatFacePro()
            }
            .frame(width: size, height: size * 1.05)
        case .master:
            ZStack {
                WingedShieldShape()
                    .fill(LinearGradient(colors: [rank.color.opacity(0.12), rank.color.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(WingedShieldShape().stroke(LinearGradient(colors: [rank.color.opacity(0.5), rank.color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.02))
                    .shadow(color: rank.glowColor, radius: size * 0.12)
                CatFaceCrown()
            }
            .frame(width: size * 1.2, height: size)
        case .legend:
            ZStack {
                SeraphimShape()
                    .fill(LinearGradient(colors: [rank.color.opacity(0.12), rank.color.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(SeraphimShape().stroke(LinearGradient(colors: [rank.color.opacity(0.5), rank.color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.02))
                    .shadow(color: rank.glowColor, radius: size * 0.12)
                CatFaceLegend()
            }
            .frame(width: size * 1.1, height: size * 1.1)
        case .mythic:
            ZStack {
                ShieldShape()
                    .fill(LinearGradient(colors: [rank.color.opacity(0.12), rank.color.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .overlay(ShieldShape().stroke(LinearGradient(colors: [rank.color.opacity(0.5), rank.color.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.025))
                    .shadow(color: rank.glowColor, radius: size * 0.12)
                CatFaceMythic()
            }
            .frame(width: size, height: size * 1.05)
        }
    }
}

// MARK: - Achievement Badge (simpler, smaller)
struct AchievementBadgeView: View {
    let tier: Int
    let maxTier: Int
    let size: CGFloat
    
    var tierColor: Color {
        let ratio = Double(tier) / Double(max(maxTier, 1))
        return Color(red: 0.3 + 0.7 * ratio, green: 0.7 - 0.4 * ratio, blue: 0.9 - 0.3 * ratio)
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [tierColor.opacity(0.15), tierColor.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size * 1.1)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .stroke(
                            LinearGradient(
                                colors: [tierColor.opacity(0.4), tierColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: tierColor.opacity(0.12), radius: size * 0.1)
            
            // Star symbol using shapes
            if tier >= maxTier {
                // Gold star
                StarShape()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .frame(width: size * 0.5, height: size * 0.5)
            } else {
                // Tier number in shield
                VStack(spacing: 2) {
                    Text("\(romanNumeral(tier))")
                        .font(.system(size: size * 0.35, weight: .bold))
                        .foregroundColor(tierColor)
                }
            }
        }
        .frame(width: size, height: size * 1.1)
    }
    
    func romanNumeral(_ n: Int) -> String {
        let roman = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        if n < roman.count { return roman[n] }
        return "\(n)"
    }
}

// MARK: - Star Shape
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let points = 5
        var path = Path()
        for i in 0..<points * 2 {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let radius = i % 2 == 0 ? r : r * 0.4
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}