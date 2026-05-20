// DesignSystem.swift

import SwiftUI

// MARK: - Forest Color Palette
extension Color {
    // Canopy greens
    static let canopyGreen    = Color(hex: "#2D5016")   // Deep forest canopy
    static let mossGreen      = Color(hex: "#4A7C3F")   // Lush moss on stone
    static let fernGreen      = Color(hex: "#6B9E5E")   // Fern frond
    static let sageGreen      = Color(hex: "#8DB87E")   // Sage in sunlight
    static let mistGreen      = Color(hex: "#B8D4A8")   // Morning mist over meadow
    static let paleLichen     = Color(hex: "#DCF0C8")   // Pale lichen on bark

    // Earth tones
    static let richSoil       = Color(hex: "#1A0F0A")   // Dark potting soil
    static let barkBrown      = Color(hex: "#3D2B1F")   // Oak bark
    static let walnutBrown    = Color(hex: "#5C3D2E")   // Walnut heartwood
    static let cedarWarm      = Color(hex: "#8B5E3C")   // Cedar in afternoon light
    static let sandyLoam      = Color(hex: "#C4956A")   // Sandy loam soil
    static let driedGrass     = Color(hex: "#D4B896")   // Dried meadow grass
    
    // Water & sky
    static let dewDrop        = Color(hex: "#A8C5DA")   // Morning dew
    static let rainwaterBlue  = Color(hex: "#7AADCC")   // Rainwater in a pot
    static let forestMist     = Color(hex: "#E8F4F0")   // Forest mist
    
    // Botanical accents
    static let wildBerry      = Color(hex: "#7B3D6E")   // Wild berry
    static let goldenPollen   = Color(hex: "#D4A017")   // Pollen dust
    static let petalCoral     = Color(hex: "#E07B6A")   // Coral flower petal
    static let mushroomCream  = Color(hex: "#F2E6CC")   // Forest mushroom cap
    static let stoneGrey      = Color(hex: "#8A9A8D")   // River stone
    
    // Background layers (dark forest floor to canopy)
    static let forestFloor    = Color(hex: "#0D1A0D")   // Forest floor at night
    static let underbrush     = Color(hex: "#142010")   // Dense underbrush
    static let midForest      = Color(hex: "#1C2B18")   // Mid-forest shadow
    static let forestDapple   = Color(hex: "#243320")   // Dappled light area
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Typography
struct CultivarFont {
    // Display: Organic, botanical feel
    static func canopy(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Georgia", size: size).weight(weight)
    }
    // Body: Legible, natural
    static func undergrowth(_ size: CGFloat) -> Font {
        .custom("Georgia", size: size)
    }
    // Mono: Data/measurements — like carved wood
    static func rings(_ size: CGFloat) -> Font {
        .custom("Courier New", size: size)
    }
    // Bold headers — old growth
    static func oldGrowth(_ size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size)
    }
}

// MARK: - Forest Background Gradients
struct ForestGradients {
    static var deepCanopy: LinearGradient {
        LinearGradient(
            colors: [.forestFloor, .underbrush, .midForest],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    static var mossCard: LinearGradient {
        LinearGradient(
            colors: [Color.mossGreen.opacity(0.3), Color.canopyGreen.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
}

// MARK: - Reusable View Modifiers

struct ForestCardStyle: ViewModifier {
    var isUrgent: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isUrgent
                        ? LinearGradient(colors: [Color.barkBrown.opacity(0.5), Color.walnutBrown.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.midForest, Color.forestDapple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isUrgent ? Color.cedarWarm.opacity(0.6) : Color.mossGreen.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.richSoil.opacity(0.5), radius: 8, x: 0, y: 4)
    }
}

struct GroveTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.richSoil.opacity(0.6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.mossGreen.opacity(0.4), lineWidth: 1)
            )
            .foregroundColor(.mushroomCream)
            .font(CultivarFont.undergrowth(15))
    }
}

// MARK: - Reusable Components

struct CultivarBadge: View {
    let text: String
    let color: Color
    let icon: String?
    
    init(_ text: String, color: Color = .mossGreen, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(CultivarFont.undergrowth(11))
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct CultivarButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, destructive, ghost
    }
    
    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(CultivarFont.undergrowth(15))
                    .fontWeight(.semibold)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .forestFloor
        case .secondary: return .mossGreen
        case .destructive: return .petalCoral
        case .ghost: return .driedGrass
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .mossGreen
        case .secondary: return .mossGreen.opacity(0.15)
        case .destructive: return .petalCoral.opacity(0.15)
        case .ghost: return .clear
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return .mossGreen.opacity(0.5)
        case .destructive: return .petalCoral.opacity(0.4)
        case .ghost: return .driedGrass.opacity(0.3)
        }
    }
}

// MARK: - Organic Divider
struct RootDivider: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.mossGreen.opacity(0.2))
                .frame(height: 1)
            Image(systemName: "leaf.fill")
                .font(.system(size: 8))
                .foregroundColor(.mossGreen.opacity(0.4))
            Rectangle()
                .fill(Color.mossGreen.opacity(0.2))
                .frame(height: 1)
        }
    }
}

// MARK: - View Extension Helpers
extension View {
    func forestCard(isUrgent: Bool = false) -> some View {
        modifier(ForestCardStyle(isUrgent: isUrgent))
    }
}

struct CultivarSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 13))
            Text(title)
                .font(CultivarFont.canopy(15, weight: .semibold))
                .foregroundColor(.mushroomCream)
        }
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf")
                .font(.system(size: 36))
                .foregroundColor(.mossGreen.opacity(0.4))
            Text(title)
                .font(CultivarFont.canopy(16, weight: .semibold))
                .foregroundColor(.driedGrass)
            Text(subtitle)
                .font(CultivarFont.undergrowth(13))
                .foregroundColor(.stoneGrey.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .forestCard()
    }
}
