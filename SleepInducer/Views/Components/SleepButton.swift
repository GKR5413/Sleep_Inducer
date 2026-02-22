import SwiftUI

struct SleepButton: View {
    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case danger
    }

    init(_ title: String, icon: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                }
                Text(title)
                    .font(.title3.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            SleepTheme.buttonGradient
        case .secondary:
            Color.white.opacity(0.1)
        case .danger:
            SleepTheme.dangerRed.opacity(0.8)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return SleepTheme.lavender
        case .danger: return .white
        }
    }
}
