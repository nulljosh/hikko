import SwiftUI
import UserNotifications

// Daily 9am local nudge, matches the cron that posts the morning idea.
enum DailyIdea {
    static func schedule() async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        let content = UNMutableNotificationContent()
        content.title = "Today's idea just flew in"
        content.body = "A new one is in the jar."
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 9), repeats: true)
        try? await center.add(UNNotificationRequest(identifier: "daily-idea", content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-idea"])
    }
}

@main
struct SparkApp: App {
    @State private var appState = AppState()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(appState)
                    .overlay { WhatsNewSheet() }
                    .onboarding(key: "spark",
                                signedIn: appState.isLoggedIn,
                                slides: sparkOnboardingSlides,
                                finishLabel: "Get started")

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.8), value: showSplash)
            .task {
                try? await Task.sleep(for: .seconds(1.2))
                showSplash = false
            }
            .task(id: appState.isLoggedIn) {
                if appState.isLoggedIn, UserDefaults.standard.object(forKey: "daily_idea") as? Bool ?? true { await DailyIdea.schedule() }
            }
        }
    }
}

struct SplashView: View {
    @State private var lit = false

    var body: some View {
        ZStack {
            Color(hex: "1c1a17").ignoresSafeArea()

            VStack(spacing: 28) {
                Image("Mark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .shadow(color: Color.bulb.opacity(lit ? 0.55 : 0.15), radius: lit ? 40 : 12)

                VStack(spacing: 8) {
                    Text("Hikko")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color(hex: "f3ede0"))
                    Text("Catch ideas before they fly away")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "f3ede0").opacity(0.6))
                }
                .opacity(lit ? 1 : 0)
                .offset(y: lit ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) { lit = true }
        }
    }
}
