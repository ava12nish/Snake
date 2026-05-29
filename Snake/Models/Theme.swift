import SwiftUI

enum Theme: String, CaseIterable, Identifiable, Codable {
    case classicGreen
    case neonGrid
    case midnightPurple
    case retroArcade
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .classicGreen: return "Classic Green"
        case .neonGrid: return "Neon Grid"
        case .midnightPurple: return "Midnight Purple"
        case .retroArcade: return "Retro Arcade"
        }
    }
    
    // Hex-based colors to avoid project asset bundle dependencies
    var primaryColorHex: String {
        switch self {
        case .classicGreen: return "34C759" // Apple Green
        case .neonGrid: return "00E5FF" // Neon Cyan
        case .midnightPurple: return "AF52DE" // Violet
        case .retroArcade: return "FF9500" // Classic Amber
        }
    }
    
    var secondaryColorHex: String {
        switch self {
        case .classicGreen: return "30B0C7" // Teal
        case .neonGrid: return "FF2D55" // Neon Pink
        case .midnightPurple: return "FFCC00" // Yellow / Gold
        case .retroArcade: return "5856D6" // Dark Blue
        }
    }
    
    var boardColorHex: String {
        switch self {
        case .classicGreen: return "1C1C1E" // Dark Grey
        case .neonGrid: return "0A0A0C" // Jet Black
        case .midnightPurple: return "120A2A" // Deep Space Purple
        case .retroArcade: return "000000" // Pure Black
        }
    }
    
    var gridLineColorHex: String {
        switch self {
        case .classicGreen: return "2C2C2E" // Slightly lighter gray
        case .neonGrid: return "1A1D29" // Cyan hue dark blue
        case .midnightPurple: return "20133A" // Purple hue gray
        case .retroArcade: return "1C1C1E" // Minimal grid
        }
    }
    
    var foodColorHex: String {
        switch self {
        case .classicGreen: return "FF3B30" // Apple Red
        case .neonGrid: return "FFCC00" // Neon Gold
        case .midnightPurple: return "00C7BE" // Teal Mint
        case .retroArcade: return "FFFFFF" // White Pixel
        }
    }
    
    var specialFoodColorHex: String {
        switch self {
        case .classicGreen: return "FFD60A" // Bright Yellow
        case .neonGrid: return "FF2D55" // Neon Red
        case .midnightPurple: return "FF2D55" // Gold
        case .retroArcade: return "FF9500" // Amber Blink
        }
    }
    
    var obstacleColorHex: String {
        switch self {
        case .classicGreen: return "8E8E93" // Grey
        case .neonGrid: return "FF3B30" // Red Laser
        case .midnightPurple: return "FF9500" // Bronze Wall
        case .retroArcade: return "8E8E93" // Grey Pixel Block
        }
    }
    
    // SwiftUI Color accessors
    var primaryColor: Color { Color(hex: primaryColorHex) }
    var secondaryColor: Color { Color(hex: secondaryColorHex) }
    var boardColor: Color { Color(hex: boardColorHex) }
    var gridLineColor: Color { Color(hex: gridLineColorHex) }
    var foodColor: Color { Color(hex: foodColorHex) }
    var specialFoodColor: Color { Color(hex: specialFoodColorHex) }
    var obstacleColor: Color { Color(hex: obstacleColorHex) }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
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
