import SwiftData
import SwiftUI

struct BudgetsView: View {
    @Query private var budgets: [MonthlyBudget]
    @Query private var transactions: [FinanceTransaction]
    @Query private var customCategories: [CustomCategory]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var showingEditor = false

    private var monthInterval: DateInterval {
        FinanceCalculations.monthInterval(containing: .now)
    }

    private var monthStart: Date { monthInterval.start }

    private var currentBudgets: [MonthlyBudget] {
        budgets
            .filter { monthInterval.contains($0.monthStart) }
            .sorted { $0.categoryName < $1.categoryName }
    }

    private var categorySpending: [String: Double] {
        Dictionary(
            uniqueKeysWithValues: FinanceCalculations
                .spendingByCategory(transactions: transactions, in: monthInterval)
                .map { ($0.name, $0.amount) }
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if currentBudgets.isEmpty {
                    ContentUnavailableView {
                        Label("Бюджеты не заданы", systemImage: "target")
                    } description: {
                        Text("Установите лимиты по категориям и следите за прогрессом в течение месяца.")
                    } actions: {
                        Button("Настроить бюджеты") { showingEditor = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            ForEach(currentBudgets) { budget in
                                budgetRow(budget)
                            }
                        } header: {
                            Text(Date.now.monthTitle)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Бюджеты")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Изменить") { showingEditor = true }
                }
            }
            .sheet(isPresented: $showingEditor) {
                BudgetEditorView(budgets: currentBudgets, monthStart: monthStart)
            }
        }
    }

    private func budgetRow(_ budget: MonthlyBudget) -> some View {
        let spent = categorySpending[budget.categoryName, default: 0]
        let progress = budget.limit > 0 ? spent / budget.limit : 0
        let progressTint: Color = progress >= 1 ? .red : (progress >= 0.8 ? .orange : .indigo)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    CategoryIconView(
                        systemName: budget.categoryIcon,
                        emoji: budget.categoryEmoji,
                        tint: tint(for: budget),
                        size: 16
                    )
                    Text(budget.categoryName)
                        .font(.headline)
                }
                Spacer()
                Text(spent.formattedCurrency(code: currencyCode))
                    .font(.subheadline.weight(.semibold))
                Text("из \(budget.limit.formattedCurrency(code: currencyCode))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(progress, 1))
                .tint(progressTint)

            if progress >= 1 {
                Text("Лимит превышен на \((spent - budget.limit).formattedCurrency(code: currencyCode))")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("Осталось \(max(0, budget.limit - spent).formattedCurrency(code: currencyCode))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 7)
    }

    private func tint(for budget: MonthlyBudget) -> Color {
        if let builtIn = FinanceCategory.find(named: budget.categoryName) {
            return builtIn.tint
        }
        if let custom = customCategories.first(where: { $0.name == budget.categoryName }) {
            return FinanceCategory.color(named: custom.colorName)
        }
        return .indigo
    }
}
