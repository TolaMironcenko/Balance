import Foundation
import SwiftData

enum BalanceModelContainer {
    static let schema = Schema([
        FinanceTransaction.self,
        MonthlyBudget.self,
        CustomCategory.self,
        SyncTombstone.self
    ])

    static var isCloudSyncEnabled: Bool {
        Bundle.main.object(forInfoDictionaryKey: "BalanceCloudKitEnabled") as? Bool == true
    }

    static func make() -> ModelContainer {
        if isCloudSyncEnabled,
           let cloudContainer = try? ModelContainer(
               for: schema,
               configurations: [ModelConfiguration(
                   schema: schema,
                   isStoredInMemoryOnly: false,
                   cloudKitDatabase: .automatic
               )]
           ) {
            return cloudContainer
        }

        let localConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [localConfiguration]
            )
        } catch {
            let recoveryConfiguration = ModelConfiguration(
                "BalanceRecovery",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )

            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [recoveryConfiguration]
                )
            } catch {
                fatalError("Не удалось создать хранилище Balance: \(error.localizedDescription)")
            }
        }
    }
}
