import SwiftUI
import UIKit

class DynamicColorManager: ObservableObject {
    @Published var dominantColor: Color = .black
    @Published var secondaryColor: Color = Color.black.opacity(0.8)
    
    func extractColors(from url: URL?) {
        guard let url = url else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    let colors = image.getDominantColors(count: 2)
                    await MainActor.run {
                        if colors.count >= 2 {
                            dominantColor = Color(colors[0])
                            secondaryColor = Color(colors[1])
                        }
                    }
                }
            } catch {}
        }
    }
}

extension UIImage {
    func getDominantColors(count: Int = 2) -> [UIColor] {
        guard let cgImage = self.cgImage else { return [.black, .darkGray] }
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let inputCGImage = resizedImage?.cgImage else { return [.black, .darkGray] }
        let width = inputCGImage.width
        let height = inputCGImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var colorCount: [UIColor: Int] = [:]
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = CGFloat(pixels[offset]) / 255.0
                let g = CGFloat(pixels[offset + 1]) / 255.0
                let b = CGFloat(pixels[offset + 2]) / 255.0
                let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                let simplified = color.simplified()
                colorCount[simplified, default: 0] += 1
            }
        }
        
        let sorted = colorCount.sorted { $0.value > $1.value }
        return Array(sorted.prefix(count).map { $0.key })
    }
}

extension UIColor {
    func simplified() -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: round(r * 4) / 4, green: round(g * 4) / 4, blue: round(b * 4) / 4, alpha: 1.0)
    }
}