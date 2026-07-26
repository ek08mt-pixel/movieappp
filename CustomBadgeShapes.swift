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

// MARK: - 2. Con Mèo (Đã tính toán tọa độ chuẩn xác để giống Mockup)
struct CatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let c = CGPoint(x: w/2, y: h/2)
        
        // Tai trái
        path.move(to: CGPoint(x: w * 0.32, y: h * 0.34))
        path.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.08), control: CGPoint(x: w * 0.26, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.26), control: CGPoint(x: w * 0.35, y: h * 0.26))
        path.closeSubpath()
        
        // Tai phải
        path.move(to: CGPoint(x: w * 0.68, y: h * 0.34))
        path.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.08), control: CGPoint(x: w * 0.74, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.26), control: CGPoint(x: w * 0.65, y: h * 0.26))
        path.closeSubpath()
        
        // Đầu tròn
        path.move(to: CGPoint(x: w * 0.42, y: h * 0.26))
        path.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.26), control: CGPoint(x: c.x, y: h * 0.14))
        path.addArc(center: c, radius: w * 0.32, startAngle: .degrees(-95), endAngle: .degrees(95), clockwise: false)
        path.closeSubpath()
        
        // Mắt
        path.addEllipse(in: CGRect(x: w * 0.38, y: h * 0.42, width: w * 0.08, height: h * 0.12))
        path.addEllipse(in: CGRect(x: w * 0.54, y: h * 0.42, width: w * 0.08, height: h * 0.12))
        
        // Mũi
        path.move(to: CGPoint(x: w * 0.48, y: h * 0.54))
        path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.54))
        path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.58))
        path.closeSubpath()
        
        // Ria trái
        path.move(to: CGPoint(x: w * 0.30, y: h * 0.46)); path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.46))
        path.move(to: CGPoint(x: w * 0.30, y: h * 0.50)); path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.50))
        path.move(to: CGPoint(x: w * 0.30, y: h * 0.54)); path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.54))
        
        // Ria phải
        path.move(to: CGPoint(x: w * 0.70, y: h * 0.46)); path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.46))
        path.move(to: CGPoint(x: w * 0.70, y: h * 0.50)); path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.50))
        path.move(to: CGPoint(x: w * 0.70, y: h * 0.54)); path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.54))
        
        return path
    }
}

// MARK: - 3. Icon Shapes cho Timeline
struct CrownIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.maxY * 0.4))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY + 4), control: CGPoint(x: rect.midX - 10, y: rect.maxY * 0.6))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.8, y: rect.maxY * 0.4), control: CGPoint(x: rect.midX + 10, y: rect.maxY * 0.6))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct LightningIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + 6))
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
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY * 0.6), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.maxY * 0.3))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.6), control: CGPoint(x: rect.maxX, y: rect.maxY * 0.3))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}