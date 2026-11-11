import SwiftUI

@main
struct JarasApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var repo = CalendarRepo()
    @StateObject private var notifier = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(theme)
                .environmentObject(repo)
                .environmentObject(notifier)
                .preferredColorScheme(theme.isDarkMode ? .dark : .light)
                .environment(\.locale, Ar.locale)
                .environment(\.layoutDirection, .rightToLeft)
                .task {
                    _ = await notifier.requestPermission()
                    repo.checkAuthorization()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        SoundManager.shared.startBackgroundKeepAlive()
                        repo.reload()
                        Task { await notifier.refreshAuthorizationStatus() }
                    } else if newPhase == .background {
                        SoundManager.shared.startBackgroundKeepAlive()
                        repo.reload()
                    }
                }
        }
    }
}
