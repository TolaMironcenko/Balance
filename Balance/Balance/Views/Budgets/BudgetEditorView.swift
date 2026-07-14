import Foundation
import SwiftData
import SwiftUI

struct BudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]

    let budgets: [MonthlyBudget]
    let monthStart: Date
    @State private var limits: [String: String]

    init(budgets: [MonthlyBudget], monthStart: Date) {
        self.budgets = budgets
        self.monthStart = monthStart
        _limits = State(initialValue: Dictionary(uniqueKeysWithValues: budgets.map {
            ($0.categoryName, String(format: "%.0f", $0.limit))
        }))
    }

    private var expenseCategories: [FinanceCategory] {
        FinanceCategory.expenseCategories + customCategories
            .filter { $0.kind == .expense }
            .map(\.financeCategory)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Введите месячный лимит. Пустое поле или 0 удалит бюджет категории.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Расходы") {
                    ForEach(expenseCategories) { category in
                        HStack(spacing: 12) {
                            CategoryIconView(
                                systemName: category.icon,
                                emoji: category.emoji,
                                tint: category.tint,
                                size: 17
                            )
                            Text(category.name)
                            Spacer()
                            TextField("0", text: binding(for: category.name))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 110)
                        }
                    }
                }
            }
            .navigationTitle("Лимиты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func binding(for categoryName: String) -> Binding<String> {
        Binding(
            get: { limits[categoryName, default: ""] },
            set: { limits[categoryName] = $0 }
        )
    }

    private func parsedLimit(for categoryName: String) -> Double {
        let text = limits[categoryName, default: ""]
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return max(0, Double(text) ?? 0)
    }

    private func save() {
        for category in expenseCategories {
            let value = parsedLimit(for: category.name)
            let existing = budgets.first { $0.categoryName == category.name }

            if value > 0 {
                if let existing {
                    existing.limit = value
                    existing.categoryIcon = category.icon
                    existing.categoryEmoji = category.emoji
                    existing.syncUpdatedAt = .now
                } else {
                    modelContext.insert(
                        MonthlyBudget(
                            categoryName: category.name,
                            categoryIcon: category.icon,
                            categoryEmoji: category.emoji,
                            limit: value,
                            monthStart: monthStart
                        )
                    )
                }
            } else if let existing {
                modelContext.deleteForSync(existing)
            }
        }
        dismiss()
    }
}
