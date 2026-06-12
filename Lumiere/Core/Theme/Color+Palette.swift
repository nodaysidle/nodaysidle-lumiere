import SwiftUI

extension Color {
    enum Lumiere {
        static let accent = Color(hex: 0xC8FF00)
        static let background = Color(hex: 0x0A0A0F)
        static let surface = Color(hex: 0x14141F)
        static let textPrimary = Color(hex: 0xF0F0F5)
        static let textSecondary = Color(hex: 0x6B6B80)
        static let error = Color(hex: 0xFF3B5C)
        static let success = Color(hex: 0x00E676)
    }

    private init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1
        )
    }
}

#Preview("Palette") {
    HStack(spacing: 12) {
        ForEach(
            [
                Color.Lumiere.accent,
                Color.Lumiere.background,
                Color.Lumiere.surface,
                Color.Lumiere.textPrimary,
                Color.Lumiere.textSecondary,
                Color.Lumiere.error,
                Color.Lumiere.success,
            ],
            id: \.self
        ) { color in
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .frame(width: 72, height: 72)
        }
    }
    .padding()
    .background(Color.Lumiere.background)
}
