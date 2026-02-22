import SwiftUI

struct GlowingMoonIcon: View {
    @State private var glowing = false

    var body: some View {
        Image(systemName: "moon.fill")
            .font(.system(size: 60))
            .foregroundStyle(SleepTheme.warmGold)
            .shadow(color: SleepTheme.warmGold.opacity(glowing ? 0.6 : 0.2), radius: glowing ? 20 : 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}
