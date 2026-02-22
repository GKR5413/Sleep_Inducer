import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthorizationViewModel()
    @StateObject private var sessionVM = SessionViewModel()

    var body: some View {
        ZStack {
            SleepTheme.backgroundGradient
                .ignoresSafeArea()

            if !authVM.isAuthorized {
                authorizationView
            } else if sessionVM.hasActiveSession {
                ActiveSessionView(sessionVM: sessionVM)
            } else {
                NavigationStack {
                    HomeView(sessionVM: sessionVM)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var authorizationView: some View {
        VStack(spacing: 32) {
            Spacer()

            GlowingMoonIcon()

            Text("Sleep Inducer")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(SleepTheme.softWhite)

            Text("Block distracting apps during sleep.\nScreen Time access is required.")
                .font(.body)
                .foregroundStyle(SleepTheme.lavender.opacity(0.8))
                .multilineTextAlignment(.center)

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(SleepTheme.dangerRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            SleepButton("Grant Access", icon: "lock.open.fill") {
                Task {
                    await authVM.requestAuthorization()
                }
            }
            .padding(.horizontal, 40)
            .disabled(authVM.isLoading)
            .opacity(authVM.isLoading ? 0.6 : 1)

            Spacer()
        }
        .padding()
    }
}
