//
//  CustomBadgeShapes.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI
import WebKit // Import WebKit để render SVG chính xác 100%

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

// MARK: - 2. SVG Renderer Dùng WebKit (Đã fix build 100%)
struct SVGIcon: UIViewRepresentable {
    let svgString: String
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let html = """
        <html><head><style>body { margin: 0; background: transparent; display: flex; justify-content: center; align-items: center; height: 100%; }</style></head>
        <body>\(svgString)</body></html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - 3. SVG Code gốc (Chính xác từ Mockup)
let catSVG = """
<svg width="50" height="50" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <path fill="white" d="M50 13C36.1 13 25 24.1 25 38C25 51.9 36.1 63 50 63C63.9 63 75 51.9 75 38C75 24.1 63.9 13 50 13ZM50 59C38.4 59 29 49.6 29 38C29 26.4 38.4 17 50 17C61.6 17 71 26.4 71 38C71 49.6 61.6 59 50 59Z"/>
  <path fill="white" d="M38 36C36.3 36 35 37.3 35 39C35 40.7 36.3 42 38 42C41.7 42 41 40.7 41 39C41 37.3 39.7 36 38 36Z"/>
  <path fill="white" d="M62 36C60.3 36 59 37.3 59 39C59 40.7 60.3 42 62 42C63.7 42 65 40.7 65 39C65 37.3 63.7 36 62 36Z"/>
  <path fill="white" d="M50 45C48 45 47 46 47 48V50C47 52 48 53 50 53C52 53 53 52 53 50V48C53 46 52 45 50 45Z"/>
</svg>
"""
let crownSVG = """
<svg width="50" height="50" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <path fill="white" d="M25 60L25 70L75 70L75 60L50 75L25 60Z"/>
  <path fill="white" d="M10 10L10 40L40 40L40 10L10 10Z"/>
</svg>
"""
let lightningSVG = """
<svg width="50" height="50" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <path fill="white" d="M50 0L40 50L45 50L40 100L70 40L60 40L70 0Z"/>
</svg>
"""
let flameSVG = """
<svg width="50" height="50" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <path fill="white" d="M50 5C40 20 40 40 40 40C40 20 30 30 10 50C10 70 30 90 50 90C70 90 90 70 90 50C70 30 60 20 60 40C60 40 60 20 50 5Z"/>
</svg>
"""