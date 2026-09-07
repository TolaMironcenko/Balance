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

// MARK: - Превью

extension BalanceModelContainer {
    /// Контейнер в памяти с демо-данными для #Preview.
    @MainActor
    static var previewContainer: ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            PreviewSampleData.seed(into: container.mainContext)
            return container
        } catch {
            fatalError("Не удалось создать контейнер для превью: \(error.localizedDescription)")
        }
    }
}

/// Демо-данные, которыми наполняется контейнер превью.
@MainActor
private enum PreviewSampleData {
    static func seed(into context: ModelContext) {
        let calendar = Calendar.current
        let monthStart = FinanceCalculations.monthInterval(containing: .now, calendar: calendar).start

        context.insert(CustomCategory(
            name: "Кофе",
            icon: "cup.and.saucer.fill",
            emoji: "☕️",
            colorName: "brown",
            kind: .expense
        ))

        let expenses: [(name: String, icon: String, emoji: String, colorName: String, amount: Double)] = [
            ("Продукты", "cart.fill", "", "auto", 3_400),
            ("Транспорт", "car.fill", "", "auto", 1_200),
            ("Развлечения", "gamecontroller.fill", "", "auto", 2_600),
            ("Подписки", "repeat", "", "auto", 649),
            ("Кофе", "cup.and.saucer.fill", "☕️", "brown", 380),
            ("Покупки", "bag.fill", "", "auto", 4_800)
        ]

        for monthOffset in 0..<6 {
            guard let anchor = calendar.date(byAdding: .month, value: -monthOffset, to: monthStart) else {
                continue
            }

            if let salaryDate = calendar.date(byAdding: .day, value: 2, to: anchor) {
                context.insert(FinanceTransaction(
                    amount: 150_000,
                    date: salaryDate,
                    note: "",
                    categoryName: "Зарплата",
                    categoryIcon: "banknote.fill",
                    kind: .income
                ))
            }

            for (index, template) in expenses.enumerated() {
                guard let date = calendar.date(byAdding: .day, value: 4 + index * 3, to: anchor) else {
                    continue
                }
                let variation = 1 + Double((monthOffset + index) % 4) * 0.08
                context.insert(FinanceTransaction(
                    amount: (template.amount * variation).rounded(),
                    date: date,
                    note: "",
                    categoryName: template.name,
                    categoryIcon: template.icon,
                    categoryEmoji: template.emoji,
                    categoryColorName: template.colorName,
                    kind: .expense
                ))
            }
        }

        let budgets: [(name: String, icon: String, emoji: String, limit: Double)] = [
            ("Продукты", "cart.fill", "", 30_000),
            ("Транспорт", "car.fill", "", 8_000),
            ("Развлечения", "gamecontroller.fill", "", 10_000),
            ("Кофе", "cup.and.saucer.fill", "☕️", 5_000)
        ]

        for budget in budgets {
            context.insert(MonthlyBudget(
                categoryName: budget.name,
                categoryIcon: budget.icon,
                categoryEmoji: budget.emoji,
                limit: budget.limit,
                monthStart: monthStart
            ))
        }
    }
}
