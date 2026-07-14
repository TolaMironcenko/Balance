import Foundation
import SwiftData
import SwiftUI

struct BalanceAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue

    @State private var desiredBalanceText = ""
    @State private var note = ""

    private var currentBalance: Double {
        FinanceCalculations.totalBalance(transactions: transactions)
    }

    private var desiredBalance: Double? {
        let normalized = desiredBalanceText
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private var difference: Double? {
        guard let desiredBalance else { return nil }
        return desiredBalance - currentBalance
    }

    private var canSave: Bool {
        guard let difference else { return false }
        return abs(difference) >= 0.005
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent(
                        "Расчётный баланс",
                        value: currentBalance.formattedCurrency(code: currencyCode)
                    )

                    HStack(alignment: .firstTextBaseline) {
                        TextField("Фактический баланс", text: $desiredBalanceText)
                            .font(.title2.bold())
                            .keyboardType(.numbersAndPunctuation)
                        Text(currencyCode)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Баланс")
                } footer: {
                    Text("Приложение создаст отдельную операцию на разницу между расчётным и фактическим балансом.")
                }

                if let difference, abs(difference) >= 0.005 {
                    Section("Корректировка") {
                        LabeledContent(
                            difference > 0 ? "Будет добавлен доход" : "Будет добавлен расход",
                            value: abs(difference).formattedCurrency(code: currencyCode)
                        )
                        TextField("Комментарий (необязательно)", text: $note)
                    }
                }
            }
            .navigationTitle("Корректировка баланса")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if desiredBalanceText.isEmpty {
                    desiredBalanceText = String(format: "%.2f", currentBalance)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let difference, canSave else { return }
        let kind: TransactionKind = difference > 0 ? .income : .expense
        modelContext.insert(
            FinanceTransaction(
                amount: abs(difference),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Ручная корректировка баланса"
                    : note.trimmingCharacters(in: .whitespacesAndNewlines),
                categoryName: "Корректировка",
                categoryIcon: "slider.horizontal.3",
                categoryEmoji: "",
                categoryColorName: "indigo",
                isBalanceAdjustment: true,
                kind: kind
            )
        )
        dismiss()
    }
}
