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
                if appState.isLoggedIn { await DailyIdea.schedule() }
            }
        }
    }
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "0a1a33")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Circle()
                    .fill(Color(hex: "f7c948"))
                    .frame(width: 44, height: 44)
                    .shadow(color: Color(hex: "f7c948").opacity(0.7), radius: 24)
                    .padding(.bottom, 12)

                Text("Hotaru")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundStyle(Color(hex: "fdfaf3"))
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
