//
//  Theme.swift
//  CatIos — Patios design system
//

import SwiftUI
import UIKit

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return L("System")
        case .light: return L("Light")
        case .dark: return L("Dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppTheme {
    static let starlight = Color.clear.fallback(light: Color(hex: "B45309"), dark: Color(hex: "FBBF24"))
    static let fae = Color.clear.fallback(light: Color(hex: "0F766E"), dark: Color(hex: "2DD4BF"))
    static let blossom = Color.clear.fallback(light: Color(hex: "BE185D"), dark: Color(hex: "F9A8D4"))
    static let lilac = Color.clear.fallback(light: Color(hex: "5B6B7A"), dark: Color(hex: "94A3B8"))
    static let meadow = Color.clear.fallback(light: Color(hex: "15803D"), dark: Color(hex: "4ADE80"))
    static let honey = Color.clear.fallback(light: Color(hex: "C2410C"), dark: Color(hex: "FDBA74"))
    static let sky = Color.clear.fallback(light: Color(hex: "1D4ED8"), dark: Color(hex: "93C5FD"))
    static let coral = Color.clear.fallback(light: Color(hex: "DC2626"), dark: Color(hex: "FCA5A5"))
    static let dusk = Color.clear.fallback(light: Color(hex: "334155"), dark: Color(hex: "CBD5E1"))
    static let tide = Color.clear.fallback(light: Color(hex: "0E7490"), dark: Color(hex: "67E8F9"))
    static let ember = Color.clear.fallback(light: Color(hex: "EA580C"), dark: Color(hex: "FDBA74"))
    static let moon = Color.clear.fallback(light: Color(hex: "F8FAF9"), dark: Color(hex: "15201C"))
    static let void = Color.clear.fallback(light: Color(hex: "F3F5F4"), dark: Color(hex: "0C1210"))

    static let palette: [Color] = [fae, meadow, sky, honey, tide, dusk, ember]

    static let primary = fae
    static let secondary = starlight
    static let background = void
    static let cardBackground = Color.clear.fallback(
        light: Color.white,
        dark: Color(hex: "17211E")
    )
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)

    static let success = meadow
    static let warning = honey
    static let danger = coral

    static let nutrition = meadow
    static let health = sky
    static let behavior = honey
    static let tasks = fae
    static let analytics = dusk
    static let assistant = tide

    static let shadowColor = Color.black.opacity(0.06)

    static let heroGradient = LinearGradient(
        colors: [
            Color.clear.fallback(light: Color(hex: "0F766E"), dark: Color(hex: "0D9488")),
            Color.clear.fallback(light: Color(hex: "115E59"), dark: Color(hex: "134E4A"))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let skyGradient = LinearGradient(
        colors: [void, moon],
        startPoint: .top,
        endPoint: .bottom
    )

    static let micGradient = LinearGradient(
        colors: [fae, tide],
        startPoint: .top,
        endPoint: .bottom
    )

    static let glowGradient = LinearGradient(
        colors: [fae, tide],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let enchantedBorder = Color.clear.fallback(
        light: Color.black.opacity(0.06),
        dark: Color.white.opacity(0.10)
    )

    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 8

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    static func titleFont(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func headlineFont() -> Font {
        .system(.headline, design: .default).weight(.semibold)
    }

    static func bodyFont() -> Font {
        .system(.body, design: .default)
    }

    static func captionFont() -> Font {
        .system(.caption, design: .default)
    }
}

extension View {
    func cardShadow() -> some View {
        shadow(color: AppTheme.shadowColor, radius: 8, y: 2)
    }

    func cardStyle(cornerRadius: CGFloat = AppTheme.cornerRadiusMedium) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.enchantedBorder, lineWidth: 1)
                }
        }
        .cardShadow()
    }

    func fantasyScreen() -> some View {
        background {
            FantasyScreenBackground()
                .ignoresSafeArea()
        }
        .scrollContentBackground(.hidden)
    }

    func fantasyNavigation() -> some View {
        toolbarBackground(.visible, for: .navigationBar)
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

struct StatusBadge: View {
    let title: String
    var tint: Color = AppTheme.primary

    var body: some View {
        Text(LocalizedStringKey(title))
            .font(AppTheme.captionFont().weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            }
            .accessibilityAddTraits(.isStaticText)
    }
}

