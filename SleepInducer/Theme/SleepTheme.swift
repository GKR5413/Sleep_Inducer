import SwiftUI

enum SleepTheme {
    // MARK: - Colors

    static let deepNavy = Color(red: 0.05, green: 0.05, blue: 0.15)
    static let midnightBlue = Color(red: 0.08, green: 0.08, blue: 0.25)
    static let indigo = Color(red: 0.35, green: 0.30, blue: 0.85)
    static let lavender = Color(red: 0.65, green: 0.55, blue: 0.95)
    static let softWhite = Color(red: 0.92, green: 0.90, blue: 0.98)
    static let warmGold = Color(red: 1.0, green: 0.85, blue: 0.40)
    static let dangerRed = Color(red: 0.90, green: 0.30, blue: 0.30)

    // MARK: - Gradients

    static let backgroundGradient = LinearGradient(
        colors: [deepNavy, midnightBlue, deepNavy],
        startPoint: .top,
        endPoint: .bottom
    )

    static let buttonGradient = LinearGradient(
        colors: [indigo, lavender],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.03)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Modifiers

    static func cardStyle() -> some ViewModifier {
        CardModifier()
    }
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(SleepTheme.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

extension View {
    func sleepCard() -> some View {
        modifier(CardModifier())
    }
}
