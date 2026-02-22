import SwiftUI

struct SettingsView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @State private var defaultStrictness: StrictnessMode = SharedSessionStore.shared.loadDefaultStrictness()
    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Default Strictness
                VStack(alignment: .leading, spacing: 12) {
                    Text("Default Mode")
                        .font(.headline)
                        .foregroundStyle(SleepTheme.softWhite)

                    Picker("Default Strictness", selection: $defaultStrictness) {
                        ForEach(StrictnessMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: defaultStrictness) {
                        SharedSessionStore.shared.saveDefaultStrictness(defaultStrictness)
                    }

                    Text(defaultStrictness.description)
                        .font(.caption)
                        .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                }
                .sleepCard()

                // Emergency Reset
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emergency Reset")
                        .font(.headline)
                        .foregroundStyle(SleepTheme.softWhite)

                    Text("Immediately removes all app blocks and clears the active session. Use only if something goes wrong.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.lavender.opacity(0.6))

                    SleepButton("Emergency Reset", icon: "exclamationmark.triangle.fill", style: .danger) {
                        showResetConfirmation = true
                    }
                }
                .sleepCard()

                // About
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                        .foregroundStyle(SleepTheme.softWhite)

                    Text("Sleep Inducer helps you maintain healthy sleep habits by blocking distracting apps during bedtime. Uses Apple Screen Time APIs.")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                }
                .sleepCard()
            }
            .padding()
        }
        .background(SleepTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Emergency Reset", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                sessionVM.emergencyReset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will immediately remove all app blocks. Are you sure?")
        }
    }
}
