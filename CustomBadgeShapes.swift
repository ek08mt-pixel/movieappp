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

// MARK: - 2. Hàm Load Ảnh từ Base64 (Đã fix lỗi cho GitHub Actions)
extension Image {
    init(svgBase64: String) {
        guard let data = Data(base64Encoded: svgBase64) else {
            self.init(systemName: "xmark.circle")
            return
        }
        #if canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            self.init(uiImage: uiImage)
        } else {
            self.init(systemName: "photo")
        }
        #else
        self.init(systemName: "photo")
        #endif
    }
}

// MARK: - 3. Bộ Icon Base64 (Lấy chính xác từ Mockup)
let catIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTUwIDEzQzM2LjEgMTMgMjUgMjQuMSAyNSAzOEMyNSA1MS45IDM2LjEgNjMgNTAgNjNDNjMuOSA2MyA3NSA1MS45IDc1IDM4Qzc1IDI0LjEgNjMuOSAxMyA1MCAxM1pNNTAgNTlDMzguNCA1OSAyOSA0OS42IDI5IDM4QzI5IDI2LjQgMzguNCAxNyA1MCAxN0M2MS42IDE3IDcxIDI2LjQgNzEgMzhDNzEgNDkuNiA2MS42IDU5IDUwIDU5WiIvPjxwYXRoIGZpbGw9IiNmZmZmZmYiIGQ9Ik0zOCAzNkMzNi4zIDM2IDM1IDM3LjMgMzUgMzlDMzUgNDAuNyAzNi4zIDQyIDM4IDQyQzQxLjcgNDIgNDEgNDAuNyA0MSAzOUM0MSAzNy4zIDM5LjcgMzYgMzggMzZaIi8+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTYyIDM2QzYwLjMgMzYgNTkgMzcuMyA1OSAzOUM1OSA0MC43IDYwLjMgNDIgNjIgNDJDNjMuNyA0MiA2NSA0MC43IDY1IDM5QzY1IDM3LjMgNjMuNyAzNiA2MiAzNloiLz48cGF0aCBmaWxsPSIjZmZmZmZmIiBkPSJNNTAgNDVDNDggNDUgNDcgNDYgNDcgNDhWNTBDNDcgNTIgNDggNTMgNTAgNTNDNTIgNTMgNTMgNTIgNTMgNTBWNDhDNTMgNDYgNTIgNDUgNTAgNDVaIi8+PC9zdmc+"

let crownIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTI1IDYwTDI1IDcwTDc1IDcwTDc1IDYwTDUwIDc1TDI1IDYwWiIvPjxwYXRoIGZpbGw9IiNmZmZmZmYiIGQ9Ik0xMCAxMEwxMCA0MEw0MCA0MEw0MCAxMEwxMCAxMFoiLz48L3N2Zz4="
let lightningIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTUwIDBMNDAgNTBMNDUgNTBMNDAgMTAwTDcwIDQwTDYwIDQwTDcwIDBaIi8+PC9zdmc+"
let flameIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTUwIDVDNDAgMjAgNDAgNDAgNDAgNDBDNDAgMjAgMzAgMzAgMTAgNTBDMTAgNzAgMzAgOTAgNTAgOTBDNzAgOTAgOTAgNzAgOTAgNTBDNzAgMzAgNjAgMjAgNjAgNDBDNjAgNDAgNjAgMjAgNTAgNVoiLz48L3N2Zz4="