import SwiftUI

struct ManualSessionView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDuration: Int = 60
    @State private var strictness: StrictnessMode = SharedSessionStore.shared.loadDefaultStrictness()

    @State private var isCustomDuration = false
    @State private var customMinutes: Int = 45

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
                                isCustomDuration = false
                            } label: {
                                Text(duration.label)
                                    .font(.body.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        (!isCustomDuration && selectedDuration == duration.minutes)
                                            ? AnyShapeStyle(SleepTheme.buttonGradient)
                                            : AnyShapeStyle(Color.white.opacity(0.08))
                                    )
                                    .foregroundStyle(
                                        (!isCustomDuration && selectedDuration == duration.minutes)
                                            ? .white
                                            : SleepTheme.lavender
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    
                    // Custom Duration Stepper
                    Button {
                        isCustomDuration = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Custom Duration")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(SleepTheme.softWhite)
                                Text("\(customMinutes) minutes")
                                    .font(.caption)
                                    .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                            }
                            Spacer()
                            Stepper("", value: $customMinutes, in: 1...1440)
                                .labelsHidden()
                                .onChange(of: customMinutes) {
                                    isCustomDuration = true
                                }
                        }
                        .padding()
                        .background(
                            isCustomDuration
                                ? Color.white.opacity(0.08)
                                : Color.white.opacity(0.03)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isCustomDuration ? SleepTheme.indigo.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )
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
                    let finalDuration = isCustomDuration ? customMinutes : selectedDuration
                    sessionVM.startManualSession(durationMinutes: finalDuration, strictness: strictness)
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
