//
//  CustomBadgeShapes.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

// MARK: - 1. Hexagon Shape
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = min(width, height) / 2
        let angleOffset = -CGFloat.pi / 2
        
        for i in 0..<6 {
            let angle = angleOffset + (CGFloat(i) * (2 * .pi / 6))
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) } 
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - 2. Con Mèo Hoạt Hình (Pixel-perfect từ Mockup)
struct ProCatIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let c = CGPoint(x: w/2, y: h/2)
        
        // 1. Tai trái
        path.move(to: CGPoint(x: w * 0.32, y: h * 0.30))
        path.addQuadCurve(to: CGPoint(x: w * 0.20, y: h * 0.08), control: CGPoint(x: w * 0.25, y: h * 0.10))
        path.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.25), control: CGPoint(x: w * 0.33, y: h * 0.25))
        path.closeSubpath()
        
        // 2. Tai phải
        path.move(to: CGPoint(x: w * 0.68, y: h * 0.30))
        path.addQuadCurve(to: CGPoint(x: w * 0.80, y: h * 0.08), control: CGPoint(x: w * 0.75, y: h * 0.10))
        path.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.25), control: CGPoint(x: w * 0.67, y: h * 0.25))
        path.closeSubpath()
        
        // 3. Đầu tròn (Vẽ nối 2 bên tai)
        path.move(to: CGPoint(x: w * 0.42, y: h * 0.25))
        path.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.25), control: CGPoint(x: c.x, y: h * 0.12))
        path.addArc(center: c, radius: w * 0.30, startAngle: .degrees(-100), endAngle: .degrees(100), clockwise: false)
        path.closeSubpath()
        
        // 4. Mắt trái
        path.addEllipse(in: CGRect(x: w * 0.38, y: h * 0.41, width: w * 0.07, height: h * 0.09))
        // 5. Mắt phải
        path.addEllipse(in: CGRect(x: w * 0.55, y: h * 0.41, width: w * 0.07, height: h * 0.09))
        
        // 6. Mũi (Tam giác)
        path.move(to: CGPoint(x: w * 0.48, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.56))
        path.closeSubpath()
        
        // 7. Ria mép (6 đường)
        let ry: [CGFloat] = [0.48, 0.52, 0.56]
        for i in 0..<3 {
            path.move(to: CGPoint(x: w * 0.32, y: h * ry[i]))
            path.addLine(to: CGPoint(x: w * 0.16, y: h * ry[i]))
            path.move(to: CGPoint(x: w * 0.68, y: h * ry[i]))
            path.addLine(to: CGPoint(x: w * 0.84, y: h * ry[i]))
        }
        return path
    }
}

// MARK: - 3. Icon Shapes dùng cho Timeline
struct CrownIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.midY * 0.6))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.midY * 0.6))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct LightningIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.midY + 6))
        path.addLine(to: CGPoint(x: rect.midX - 4, y: rect.midY + 6))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - 6))
        path.addLine(to: CGPoint(x: rect.midX + 4, y: rect.midY - 6))
        path.closeSubpath()
        return path
    }
}

struct FlameIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY * 0.8), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: 0), control: CGPoint(x: rect.minX, y: rect.midY * 0.5))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY * 0.8), control: CGPoint(x: rect.maxX, y: rect.midY * 0.5))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

struct MasksIcon: Shape {
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