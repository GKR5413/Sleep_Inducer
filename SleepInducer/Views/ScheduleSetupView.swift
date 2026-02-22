import SwiftUI

struct ScheduleSetupView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Enable toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nightly Schedule")
                            .font(.headline)
                            .foregroundStyle(SleepTheme.softWhite)
                        Text("Automatically block apps at bedtime")
                            .font(.caption)
                            .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.schedule.isEnabled)
                        .labelsHidden()
                        .tint(SleepTheme.indigo)
                }
                .sleepCard()

                if viewModel.schedule.isEnabled {
                    // Time pickers
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bedtime")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(SleepTheme.lavender)
                            DatePicker("", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }

                        Divider()
                            .background(Color.white.opacity(0.1))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wake Up")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(SleepTheme.lavender)
                            DatePicker("", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                    }
                    .sleepCard()

                    // Strictness picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mode")
                            .font(.headline)
                            .foregroundStyle(SleepTheme.softWhite)

                        Picker("Strictness", selection: $viewModel.schedule.strictness) {
                            ForEach(StrictnessMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .sleepCard()
                }

                // Save button
                SleepButton("Save Schedule", icon: "checkmark") {
                    viewModel.save()
                    dismiss()
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.3), value: viewModel.schedule.isEnabled)
        }
        .background(SleepTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}
