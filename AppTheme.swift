//
//  AppTheme.swift
//  movieapp
//
//  Created by (Your App Name) on 2026.
//

import SwiftUI

// MARK: - Color Extensions cho toàn bộ App
extension Color {
    // Background đen chính
    static let appBackground = Color(red: 0.06, green: 0.06, blue: 0.06) // #0F0F0F
    
    // Màu nền cho Card
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.12) // #1E1E1E
    
    // Màu chữ
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
    static let textTertiary = Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
    
    // Glow
    static let activeGlow = Color.white.opacity(0.15)
    static let inactiveDim = Color.white.opacity(0.08)
}