//
//  Theme.swift
//  CatEmotionAI
//

import SwiftUI
import UIKit

enum AppTheme {

    // MARK: - Brand Colors (Patios — warm pet-care palette)

    static let primary = Color("BrandPrimary", bundle: nil)
        .fallback(light: Color(red: 0.20, green: 0.55, blue: 0.52),
                  dark: Color(red: 0.35, green: 0.72, blue: 0.68))

    static let secondary = Color("BrandSecondary", bundle: nil)
        .fallback(light: Color(red: 0.95, green: 0.55, blue: 0.38),
                  dark: Color(red: 1.0, green: 0.62, blue: 0.45))

    static let background = Color("BrandBackground", bundle: nil)
        .fallback(light: Color(red: 0.97, green: 0.97, blue: 0.99),
                  dark: Color(red: 0.07, green: 0.07, blue: 0.09))

    static let cardBackground = Color("BrandCard", bundle: nil)
        .fallback(light: .white,
                  dark: Color(red: 0.12, green: 0.12, blue: 0.15))

    static let textPrimary = Color("BrandTextPrimary", bundle: nil)
        .fallback(light: Color(red: 0.09, green: 0.09, blue: 0.12),
                  dark: Color(red: 0.95, green: 0.95, blue: 0.97))

    static let textSecondary = Color("BrandTextSecondary", bundle: nil)
        .fallback(light: Color(red: 0.45, green: 0.45, blue: 0.5),
                  dark: Color(red: 0.65, green: 0.65, blue: 0.7))

    static let success = Color(red: 0.30, green: 0.75, blue: 0.48)
    static let warning = Color(red: 0.98, green: 0.68, blue: 0.25)
    static let danger  = Color(red: 0.94, green: 0.35, blue: 0.35)

    static let shadowColor = Color.black.opacity(0.08)

    // MARK: - Gradients

    static let heroGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let micGradient = LinearGradient(
        colors: [primary, primary.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Radii & Spacing

    static let cornerRadiusLarge: CGFloat = 28
    static let cornerRadiusMedium: CGFloat = 20
    static let cornerRadiusSmall: CGFloat = 14

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - App identity

    static let appDisplayName = "Patios"
}

// MARK: - Typography (Dynamic Type–friendly)

enum AppTypography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title2 = Font.title2.weight(.bold)
    static let headline = Font.headline.weight(.semibold)
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let caption = Font.caption
    static let button = Font.headline.weight(.semibold)
}

private struct CardShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content.shadow(
            color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.08),
            radius: 16, x: 0, y: 8
        )
    }
}

extension View {
    func cardShadow() -> some View {
        modifier(CardShadowModifier())
    }

    func cardStyle(cornerRadius: CGFloat = AppTheme.cornerRadiusMedium) -> some View {
        self
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .cardShadow()
    }

    /// Standard screen chrome: brand background + readable default tint.
    func patiosScreenBackground() -> some View {
        self
            .background(AppTheme.background.ignoresSafeArea())
            .tint(AppTheme.primary)
    }
}

extension Color {
    func fallback(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            a = 255
            r = (int >> 8) * 17
            g = (int >> 4 & 0xF) * 17
            b = (int & 0xF) * 17
        case 6:
            a = 255
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF
        case 8:
            r = int >> 24
            g = int >> 16 & 0xFF
            b = int >> 8 & 0xFF
            a = int & 0xFF
        default:
            a = 255
            r = 0
            g = 0
            b = 0
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
