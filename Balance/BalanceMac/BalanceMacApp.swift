import SwiftData
import SwiftUI

@main
struct BalanceMacApp: App {
    private let modelContainer = BalanceModelContainer.make()
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .frame(minWidth: 900, minHeight: 600)
                .tint(.indigo)
                .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 1100, height: 720)
    }
}
