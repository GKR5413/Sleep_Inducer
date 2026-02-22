import SwiftUI

struct HealthInsightsCard: View {
    @StateObject var healthManager = HealthKitManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.pink)
                    .font(.title2)
                Text("Health Insights")
                    .font(.headline)
                    .foregroundColor(SleepTheme.softWhite)
                Spacer()
                if !healthManager.isAuthorized {
                    Button("Enable") {
                        healthManager.requestAuthorization()
                    }
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.lavender)
                }
            }
            
            if healthManager.isAuthorized {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Latest Heart Rate")
                                .font(.caption)
                                .foregroundColor(SleepTheme.lavender)
                            Text("\(Int(healthManager.latestHeartRate)) BPM")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(SleepTheme.softWhite)
                        }
                        Spacer()
                        if healthManager.latestHeartRate > 80 {
                            Text("High HR - Consider Sleep Mode")
                                .font(.caption2)
                                .padding(6)
                                .background(SleepTheme.dangerRed.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(SleepTheme.dangerRed)
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(SleepTheme.warmGold)
                        Text("On nights you use Sleep Inducer, you get \(healthManager.sleepImprovementMinutes) mins more Deep Sleep.")
                            .font(.subheadline)
                            .foregroundColor(SleepTheme.softWhite.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                Text("Connect HealthKit to see how Sleep Inducer improves your sleep quality.")
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.softWhite.opacity(0.6))
            }
        }
        .sleepCard()
    }
}
