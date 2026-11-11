import SwiftUI

/// Emerald Green palette and Dynamic Dark/Light theme tokens (Dark Mode is default).
final class ThemeManager: ObservableObject {
    @AppStorage("dark_mode") var isDarkMode: Bool = true

    var bg: Color { isDarkMode ? Color(hex: 0x0D1512) : Color(hex: 0xF4F8F6) }
    var card: Color { isDarkMode ? Color(hex: 0x16221E) : Color(hex: 0xFFFFFF) }
    var line: Color { isDarkMode ? Color(hex: 0x23332D) : Color(hex: 0xE1EBE6) }
    var ink: Color { isDarkMode ? Color(hex: 0xF2FBF6) : Color(hex: 0x0F241C) }
    var inkSoft: Color { isDarkMode ? Color(hex: 0x98ADA3) : Color(hex: 0x566E64) }
    var inkFaint: Color { isDarkMode ? Color(hex: 0x63786F) : Color(hex: 0x8BA399) }
    var primaryTint: Color { isDarkMode ? Color(hex: 0x13382C) : Color(hex: 0xE6F7F0) }
    var sunTint: Color { isDarkMode ? Color(hex: 0x2A2210) : Color(hex: 0xFEF3C7) }
    var sunInk: Color { isDarkMode ? Color(hex: 0xFDE68A) : Color(hex: 0xB45309) }
    var mintTint: Color { isDarkMode ? Color(hex: 0x12382E) : Color(hex: 0xD1FAE5) }
}

enum JarasPalette {
    static let primary = Color(hex: 0x10B981)
    static let primaryDeep = Color(hex: 0x059669)
    static let forest = Color(hex: 0x047857)
    static let capsuleTop = Color(hex: 0x16A34A)
    static let capsuleMid = Color(hex: 0x15803D)
    static let capsuleBottom = Color(hex: 0x0D5325)
    static let sun = Color(hex: 0xFBBF24)
    static let sunDeep = Color(hex: 0xD97706)
    static let sunLight = Color(hex: 0xFDE68A)
    static let mint = Color(hex: 0x34D399)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x047857), Color(hex: 0x059669), Color(hex: 0x10B981)],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )

    static let capsuleGradient = LinearGradient(
        colors: [capsuleTop, capsuleMid, capsuleBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
