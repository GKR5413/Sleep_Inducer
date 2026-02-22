import SwiftUI

struct HomeView: View {
    @ObservedObject var sessionVM: SessionViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    GlowingMoonIcon()

                    Text("Sleep Inducer")
                        .font(.title.weight(.bold))
                        .foregroundStyle(SleepTheme.softWhite)

                    Text("Time to wind down")
                        .font(.subheadline)
                        .foregroundStyle(SleepTheme.lavender.opacity(0.7))
                }
                .padding(.top, 20)

                // Health Insights Card
                HealthInsightsCard()

                // Start Now Card
                NavigationLink {
                    ManualSessionView(sessionVM: sessionVM)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Start Now", systemImage: "moon.zzz.fill")
                                .font(.headline)
                                .foregroundStyle(SleepTheme.softWhite)
                            Text("Block apps for a set duration")
                                .font(.caption)
                                .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(SleepTheme.lavender.opacity(0.4))
                    }
                    .sleepCard()
                }

                // Nightly Schedule Card
                NavigationLink {
                    ScheduleSetupView()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Nightly Schedule", systemImage: "calendar.badge.clock")
                                .font(.headline)
                                .foregroundStyle(SleepTheme.softWhite)
                            Text("Set a recurring bedtime block")
                                .font(.caption)
                                .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(SleepTheme.lavender.opacity(0.4))
                    }
                    .sleepCard()
                }

                // Allowed Apps Card
                NavigationLink {
                    AllowedAppsView()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Allowed Apps", systemImage: "checkmark.shield.fill")
                                .font(.headline)
                                .foregroundStyle(SleepTheme.softWhite)
                            Text("Choose apps that stay accessible")
                                .font(.caption)
                                .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(SleepTheme.lavender.opacity(0.4))
                    }
                    .sleepCard()
                }

                // Settings Card
                NavigationLink {
                    SettingsView(sessionVM: sessionVM)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Settings", systemImage: "gearshape.fill")
                                .font(.headline)
                                .foregroundStyle(SleepTheme.softWhite)
                            Text("Defaults and emergency reset")
                                .font(.caption)
                                .foregroundStyle(SleepTheme.lavender.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(SleepTheme.lavender.opacity(0.4))
                    }
                    .sleepCard()
                }
            }
            .padding(.horizontal)
        }
        .background(SleepTheme.backgroundGradient.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
