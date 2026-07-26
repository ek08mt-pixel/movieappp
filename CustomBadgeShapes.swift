//
//  CustomBadgeShapes.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

// MARK: - 1. Hexagon Shape (Giữ nguyên)
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

// MARK: - 2. Hàm tiện ích chuyển SVG String thành Image
extension Image {
    init(svgBase64: String) {
        // Tạo Data từ Base64 String
        let data = Data(base64Encoded: svgBase64) ?? Data()
        // Tạo UIImage từ Data và khởi tạo Image
        #if canImport(UIKit)
        let uiImage = UIImage(data: data) ?? UIImage()
        self.init(uiImage: uiImage)
        #else
        self.init(systemName: "photo")
        #endif
    }
}

// MARK: - 3. Base64 SVG của Mèo (Giống 100% Mockup)
let catIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik01MCAxM0MzNi4xIDEzIDI1IDI0LjEgMjUgMzhDMjUgNTEuOSAzNi4xIDYzIDUwIDYzQzYzLjkgNjMgNzUgNTEuOSA3NSAzOEM3NSAyNC4xIDYzLjkgMTMgNTAgMTNaTTUwIDU5QzM4LjQgNTkgMjkgNDkuNiAyOSAzOEMyOSAyNi40IDM4LjQgMTcgNTAgMTdDNjEuNiAxNyA3MSAyNi40IDcxIDM4QzcxIDQ5LjYgNjEuNiA1OSA1MCA1OVoiLz48cGF0aCBmaWxsPSJ3aGl0ZSIgZD0iTTM4IDM2QzM2LjMgMzYgMzUgMzcuMyAzNSAzOUMzNSA0MC43IDM2LjMgNDIgMzggNDJDNDEuNyA0MiA0MSA0MC43IDQxIDM5QzQxIDM3LjMgMzkuNyAzNiAzOCAzNloiLz48cGF0aCBmaWxsPSJ3aGl0ZSIgZD0iTTYyIDM2QzYwLjMgMzYgNTkgMzcuMyA1OSAzOUM1OSA0MC43IDYwLjMgNDIgNjIgNDJDNjMuNyA0MiA2NSA0MC43IDY1IDM5QzY1IDM3LjMgNjMuNyAzNiA2MiAzNloiLz48cGF0aCBmaWxsPSJ3aGl0ZSIgZD0iTTUwIDQ1QzQ4IDQ1IDQ3IDQ2IDQ3IDQ4VjUwQzQ3IDUyIDQ4IDUzIDUwIDUzQzUyIDUzIDUzIDUyIDUzIDUwVjQ4QzUzIDQ2IDUyIDQ1IDUwIDQ1WiIvPjwvc3ZnPg=="

// MARK: - 4. Base64 SVG của các Icon Timeline (Crown, Lightning, Flame, Drama Masks)
let crownIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTI1IDYwTDI1IDcwTDc1IDcwTDc1IDYwTDUwIDc1TDI1IDYwWiIvPjxwYXRoIGZpbGw9IiNmZmZmZmYiIGQ9Ik0xMCAxMEwxMCA0MEw0MCA0MEw0MCAxMEwxMCAxMFoiLz48L3N2Zz4="
let lightningIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTUwIDBMNDAgNTBMNDUgNTBMNDAgMTAwTDcwIDQwTDYwIDQwTDcwIDBaIi8+PC9zdmc+"
let flameIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTUwIDVDNDAgMjAgNDAgNDAgNDAgNDBDNDAgMjAgMzAgMzAgMTAgNTBDMTAgNzAgMzAgOTAgNTAgOTBDNzAgOTAgOTAgNzAgOTAgNTBDNzAgMzAgNjAgMjAgNjAgNDBDNjAgNDAgNjAgMjAgNTAgNVoiLz48L3N2Zz4="
let masksIconSVG = "PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTI1IDI1QzE1IDI1IDUgMzUgNSA0NUM1IDU1IDE1IDY1IDI1IDY1QzM1IDY1IDQ1IDU1IDQ1IDQ1QzQ1IDM1IDM1IDI1IDI1IDI1Wk0yNSA1NEMxOCA1NCAxMyA0OCAxMyA0MkMxMyAzNiAxOCAzMCAyNSAzMEMzMiAzMCAzNyAzNiAzNyA0MkMzNyA0OCAzMiA1NCAyNSA1NFoiLz48cGF0aCBmaWxsPSIjZmZmZmZmIiBkPSJNNzUgMjVDNjUgMjUgNTUgMzUgNTUgNDVDNTUgNTUgNjUgNjUgNzUgNjVDODUgNjUgOTUgNTUgOTUgNDVDOTUgMzUgODUgMjUgNzUgMjVaTTc1IDU0QzY4IDU0IDYzIDQ4IDYzIDQyQzYzIDM2IDY4IDMwIDc1IDMwQzgyIDMwIDg3IDM2IDg3IDQyQzg3IDQ4IDgyIDU0IDc1IDU0WiIvPjwvc3ZnPg=="