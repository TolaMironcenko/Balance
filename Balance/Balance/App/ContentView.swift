import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Обзор", systemImage: "chart.pie.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("Аналитика", systemImage: "chart.xyaxis.line")
                }

            TransactionsView()
                .tabItem {
                    Label("Операции", systemImage: "list.bullet.rectangle")
                }

            BudgetsView()
                .tabItem {
                    Label("Бюджеты", systemImage: "target")
                }

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
        }
        .task {
            while !Task.isCancelled {
                await ServerAccountStore.shared.sync(context: modelContext)
                try? await Task.sleep(nanoseconds: 120_000_000_000)
            }
        }
    }
}

#Preview("Главный экран") {
    ContentView()
        .modelContainer(BalanceModelContainer.previewContainer)
}
