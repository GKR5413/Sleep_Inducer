import SwiftUI
import FamilyControls

struct AllowedAppsView: View {
    @StateObject private var viewModel = AllowedAppsViewModel()

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("These apps will remain accessible during sleep sessions.")
                    .font(.subheadline)
                    .foregroundStyle(SleepTheme.lavender.opacity(0.7))
                    .multilineTextAlignment(.center)

                Text("Phone and Messages are recommended.")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.lavender.opacity(0.5))
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Apple's built-in app picker
            FamilyActivityPicker(selection: $viewModel.activitySelection)
                .onChange(of: viewModel.activitySelection) {
                    viewModel.save()
                }
        }
        .background(SleepTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Allowed Apps")
        .navigationBarTitleDisplayMode(.inline)
    }
}
