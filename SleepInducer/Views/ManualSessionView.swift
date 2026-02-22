import SwiftUI

struct ManualSessionView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDuration: Int = 60
    @State private var strictness: StrictnessMode = SharedSessionStore.shared.loadDefaultStrictness()

    private let durations: [(label: String, minutes: Int)] = [
        ("30m", 30),
        ("1h", 60),
        ("2h", 120),
        ("4h", 240),
        ("6h", 360),
        ("8h", 480)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Duration Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.headline)
                        .foregroundStyle(SleepTheme.softWhite)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(durations, id: \.minutes) { duration in
                            Button {
                                selectedDuration = duration.minutes
                            } label: {
                                Text(duration.label)
                                    .font(.body.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        selectedDuration == duration.minutes
                                            ? AnyShapeStyle(SleepTheme.buttonGradient)
                                            : AnyShapeStyle(Color.white.opacity(0.08))
                                    )
                                    .foregroundStyle(
                                        selectedDuration == duration.minutes
                                            ? .white
                                            : SleepTheme.lavender
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }

                // Strictness Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mode")
                        .font(.headline)
                        .foregroundStyle(SleepTheme.softWhite)

                    ForEach(StrictnessMode.allCases) { mode in
                        Button {
                            strictness = mode
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.displayName)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(SleepTheme.softWhite)
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                                }
                                Spacer()
                                Image(systemName: strictness == mode ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(strictness == mode ? SleepTheme.indigo : SleepTheme.lavender.opacity(0.3))
                                    .font(.title3)
                            }
                            .padding()
                            .background(
                                strictness == mode
                                    ? Color.white.opacity(0.08)
                                    : Color.white.opacity(0.03)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        strictness == mode ? SleepTheme.indigo.opacity(0.5) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }

                // Start Button
                SleepButton("Start Sleep Session", icon: "moon.fill") {
                    sessionVM.startManualSession(durationMinutes: selectedDuration, strictness: strictness)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(SleepTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Start Session")
        .navigationBarTitleDisplayMode(.inline)
    }
}
