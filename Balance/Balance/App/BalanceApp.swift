import SwiftData
import SwiftUI

@main
struct BalanceApp: App {
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    private let modelContainer = BalanceModelContainer.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.indigo)
                .preferredColorScheme(
                    AppTheme(rawValue: appTheme)?.colorScheme
                )
        }
        .modelContainer(modelContainer)
    }
}
