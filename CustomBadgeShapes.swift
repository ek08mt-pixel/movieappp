//
//  CustomBadgeShapes.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

// MARK: - 1. Hexagon Shape (Hình lục giác chính)
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = min(width, height) / 2
        // Điều chỉnh góc để đỉnh nhọn quay lên trên
        let angleOffset = -CGFloat.pi / 2
        
        for i in 0..<6 {
            let angle = angleOffset + (CGFloat(i) * (2 * .pi / 6))
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

// MARK: - 2. Cat Avatar (Con mèo đen trong Hero Card)
struct ProCatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // 1. Đầu mèo (Hình tròn/bầu dục)
        path.addEllipse(in: CGRect(x: w * 0.25, y: h * 0.25, width: w * 0.5, height: h * 0.4))
        
        // 2. Tai trái
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.15), control: CGPoint(x: w * 0.2, y: h * 0.2))
        path.addQuadCurve(to: CGPoint(x: w * 0.38, y: h * 0.25), control: CGPoint(x: w * 0.3, y: h * 0.25))
        path.closeSubpath()
        
        // 3. Tai phải
        path.move(to: CGPoint(x: w * 0.7, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.15), control: CGPoint(x: w * 0.8, y: h * 0.2))
        path.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.25), control: CGPoint(x: w * 0.7, y: h * 0.25))
        path.closeSubpath()
        
        // 4. Mắt (2 hình tròn)
        path.addEllipse(in: CGRect(x: w * 0.35, y: h * 0.38, width: w * 0.08, height: h * 0.12))
        path.addEllipse(in: CGRect(x: w * 0.57, y: h * 0.38, width: w * 0.08, height: h * 0.12))
        
        // 5. Mũi (Tam giác)
        path.move(to: CGPoint(x: w * 0.48, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.60))
        path.closeSubpath()
        
        // 6. Ria mép trái
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.50))
        path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.52))
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.58))
        path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.58))
        
        // 7. Ria mép phải
        path.move(to: CGPoint(x: w * 0.9, y: h * 0.50))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.52))
        path.move(to: CGPoint(x: w * 0.9, y: h * 0.58))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.58))
        
        return path
    }
}

// MARK: - 3. Icon Shapes (Thay thế SF Symbols cho danh hiệu)
struct LightningShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + 8))
        path.addLine(to: CGPoint(x: rect.midX - 6, y: rect.midY + 8))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - 8))
        path.addLine(to: CGPoint(x: rect.midX + 6, y: rect.midY - 8))
        path.closeSubpath()
        return path
    }
}

struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX, y: rect.maxY - 8))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY + 10))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX, y: rect.minY + 10))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY - 8))
        return path
    }
}

struct MasksShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Left Mask
        path.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.3))
        path.addEllipse(in: CGRect(x: rect.width * 0.15, y: rect.height * 0.3, width: rect.width * 0.3, height: rect.height * 0.4))
        path.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.4))
        path.move(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.4))
        
        // Right Mask
        path.move(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.45))
        path.addEllipse(in: CGRect(x: rect.width * 0.45, y: rect.height * 0.45, width: rect.width * 0.35, height: rect.height * 0.4))
        path.move(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.65))
        path.addLine(to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.55))
        path.move(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.65))
        path.addLine(to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.55))
        
        return path
    }
}

struct CrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.maxY * 0.4))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY * 0.7), control: CGPoint(x: rect.midX - 10, y: rect.maxY * 0.6))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.8, y: rect.maxY * 0.4), control: CGPoint(x: rect.midX + 10, y: rect.maxY * 0.6))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 4. Hexagon Badge Icon Combo (Dùng cho Timeline Row)
struct HexagonBadgeIcon<Content: Shape>: View {
    let shape: Content
    let isUnlocked: Bool
    
    var body: some View {
        ZStack {
            // Nền tối
            HexagonShape()
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .frame(width: 40, height: 44)
            
            // Viền
            HexagonShape()
                .stroke(isUnlocked ? Color.white.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: 40, height: 44)
            
            // Icon nội dung
            shape
                .fill(isUnlocked ? Color.white : Color.white.opacity(0.15))
                .frame(width: 18, height: 18)
                .scaleEffect(isUnlocked ? 1.0 : 0.8)
        }
        // Hiệu ứng Glow nếu đã mở khóa
        .overlay(
            Group {
                if isUnlocked {
                    HexagonShape()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .blur(radius: 6)
                        .frame(width: 40, height: 44)
                }
            }
        )
    }
}