import SwiftUI

/// Accent colors for the sample cards, matching the project logo's gradient.
enum Palette {
    static let accents: [Color] = [
        Color(red: 0.49, green: 0.36, blue: 1.00),
        Color(red: 0.31, green: 0.49, blue: 0.97),
        Color(red: 0.20, green: 0.60, blue: 0.92),
        Color(red: 0.00, green: 0.72, blue: 0.77),
        Color(red: 0.36, green: 0.44, blue: 0.98),
        Color(red: 0.60, green: 0.40, blue: 0.99),
    ]

    static func accent(_ index: Int) -> Color {
        accents[abs(index) % accents.count]
    }
}
