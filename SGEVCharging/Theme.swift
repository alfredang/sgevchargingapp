import SwiftUI

enum Theme {
    static let primary = Color(red: 0.02, green: 0.48, blue: 0.36)
    static let secondary = Color(red: 0.12, green: 0.34, blue: 0.62)
    static let highlight = Color(red: 0.96, green: 0.67, blue: 0.18)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let ink = Color(uiColor: .label)
    static let mutedInk = Color(uiColor: .secondaryLabel)
}

extension View {
    func appCard(padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}
