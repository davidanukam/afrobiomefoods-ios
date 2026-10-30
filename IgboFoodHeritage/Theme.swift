import SwiftUI
import UIKit

struct Palette {
    let forest: Color
    let forestLight: Color
    let cream: Color
    let inverse: Color
    let gold: Color
    let text: Color
    let textMuted: Color
    let border: Color
    let card: Color
    let accent: Color
    let danger: Color
    let overlay: Color

    static let standard = Palette(
        forest: Color(hex: 0x16382A),
        forestLight: Color(hex: 0x2F6A4C),
        cream: Color(hex: 0xE4EBE3),
        inverse: Color(hex: 0xF4F8F4),
        gold: Color(hex: 0xC9A36A),
        text: Color(hex: 0x14201A),
        textMuted: Color(hex: 0x5C6560),
        border: Color(hex: 0xC5D4C3),
        card: .white,
        accent: Color(hex: 0x2F6A4C),
        danger: Color(hex: 0x9B2226),
        overlay: Color(hex: 0x14201A).opacity(0.45)
    )

    static let highContrast = Palette(
        forest: .black,
        forestLight: Color(hex: 0x1A1A1A),
        cream: .white,
        inverse: .white,
        gold: Color(hex: 0xFFD700),
        text: .black,
        textMuted: .black,
        border: .black,
        card: .white,
        accent: Color(hex: 0x006400),
        danger: Color(hex: 0x8B0000),
        overlay: Color.black.opacity(0.55)
    )

    var uiCream: UIColor { UIColor(cream) }
    var uiCard: UIColor { UIColor(card) }
    var uiForest: UIColor { UIColor(forest) }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.standard
}

private struct AppFontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

private struct HighContrastKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }

    var appFontScale: CGFloat {
        get { self[AppFontScaleKey.self] }
        set { self[AppFontScaleKey.self] = newValue }
    }

    var highContrast: Bool {
        get { self[HighContrastKey.self] }
        set { self[HighContrastKey.self] = newValue }
    }
}

enum TextKind {
    case title, subtitle, body, label, caption, eyebrow

    var size: CGFloat {
        switch self {
        case .title: return 28
        case .subtitle: return 20
        case .body: return 17
        case .label: return 15
        case .caption: return 13
        case .eyebrow: return 12
        }
    }

    var weight: Font.Weight {
        switch self {
        case .title: return .heavy
        case .subtitle: return .bold
        case .body: return .regular
        case .label: return .semibold
        case .caption: return .regular
        case .eyebrow: return .semibold
        }
    }
}

struct StyledText: View {
    @Environment(\.appFontScale) private var scale
    var text: String
    var kind: TextKind = .body
    var color: Color
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(text)
            .font(.system(size: kind.size * scale, weight: kind.weight))
            .foregroundStyle(color)
            .multilineTextAlignment(alignment)
    }
}
