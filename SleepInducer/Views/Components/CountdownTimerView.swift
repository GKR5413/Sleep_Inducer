import SwiftUI

struct CountdownTimerView: View {
    let endsAt: Date
    let totalDuration: TimeInterval

    @State private var remaining: TimeInterval = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let rem = max(0, endsAt.timeIntervalSince(now))
            let progress = 1.0 - (rem / totalDuration)

            VStack(spacing: 12) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 200, height: 200)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                        .stroke(
                            SleepTheme.buttonGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    // Time display
                    VStack(spacing: 4) {
                        Text(formatTime(rem))
                            .font(.system(size: 40, weight: .light, design: .monospaced))
                            .foregroundStyle(SleepTheme.softWhite)

                        Text("remaining")
                            .font(.caption)
                            .foregroundStyle(SleepTheme.lavender.opacity(0.7))
                    }
                }
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
