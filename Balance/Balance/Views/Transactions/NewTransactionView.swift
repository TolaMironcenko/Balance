import Foundation
import SwiftData
import SwiftUI

struct NewTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]

    private let transactionToEdit: FinanceTransaction?

    @State private var kind: TransactionKind
    @State private var amountText: String
    @State private var categoryName: String
    @State private var date: Date
    @State private var note: String

    init(transaction: FinanceTransaction? = nil) {
        transactionToEdit = transaction
        let initialKind = transaction?.kind ?? .expense
        _kind = State(initialValue: initialKind)
        _amountText = State(initialValue: transaction.map {
            String(format: "%.2f", $0.amount)
        } ?? "")
        _categoryName = State(initialValue: transaction?.categoryName
            ?? FinanceCategory.categories(for: initialKind)[0].name)
        _date = State(initialValue: transaction?.date ?? .now)
        _note = State(initialValue: transaction?.note ?? "")
    }

    private var parsedAmount: Double? {
        let normalized = amountText
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0 else { return nil }
        return value
    }

    private var availableCategories: [FinanceCategory] {
        var categories = FinanceCategory.categories(for: kind) + customCategories
            .filter { $0.kind == kind }
            .map(\.financeCategory)

        if let transactionToEdit,
           transactionToEdit.kind == kind,
           !categories.contains(where: { $0.name == transactionToEdit.categoryName }) {
            categories.append(
                FinanceCategory(
                    id: "archived-\(transactionToEdit.id.uuidString)",
                    name: transactionToEdit.categoryName,
                    icon: transactionToEdit.categoryIcon,
                    emoji: transactionToEdit.categoryEmoji,
                    colorName: transactionToEdit.categoryColorName
                )
            )
        }
        return categories
    }

    private var selectedCategory: FinanceCategory {
        availableCategories.first { $0.name == categoryName }
            ?? FinanceCategory.categories(for: kind)[0]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Тип", selection: $kind) {
                        ForEach(TransactionKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(transactionToEdit?.isBalanceAdjustment == true)
                    .onChange(of: kind) { _, newKind in
                        categoryName = FinanceCategory.categories(for: newKind)[0].name
                    }

                    HStack(alignment: .firstTextBaseline) {
                        TextField("0", text: $amountText)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                        Text("сумма")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Категория") {
                    Picker("Категория", selection: $categoryName) {
                        ForEach(availableCategories) { category in
                            HStack {
                                CategoryIconView(
                                    systemName: category.icon,
                                    emoji: category.emoji,
                                    tint: category.tint,
                                    size: 16
                                )
                                Text(category.name)
                            }
                                .tag(category.name)
                        }
                    }
                    .disabled(transactionToEdit?.isBalanceAdjustment == true)
                }

                if transactionToEdit?.isBalanceAdjustment == true {
                    Section {
                        Label(
                            "Корректировка влияет только на общий баланс и не учитывается в аналитике доходов и расходов.",
                            systemImage: "info.circle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                Section("Детали") {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                    TextField("Заметка (необязательно)", text: $note)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(transactionToEdit == nil ? "Сохранить" : "Готово", action: save)
                        .fontWeight(.semibold)
                        .disabled(parsedAmount == nil)
                }
            }
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let category = selectedCategory
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let transactionToEdit {
            transactionToEdit.amount = amount
            transactionToEdit.date = date
            transactionToEdit.note = trimmedNote
            transactionToEdit.categoryName = category.name
            transactionToEdit.categoryIcon = category.icon
            transactionToEdit.categoryEmoji = category.emoji
            transactionToEdit.categoryColorName = category.colorName
            transactionToEdit.kind = kind
            transactionToEdit.syncUpdatedAt = .now
        } else {
            modelContext.insert(
                FinanceTransaction(
                    amount: amount,
                    date: date,
                    note: trimmedNote,
                    categoryName: category.name,
                    categoryIcon: category.icon,
                    categoryEmoji: category.emoji,
                    categoryColorName: category.colorName,
                    kind: kind
                )
            )
        }
        dismiss()
    }

    private var navigationTitle: String {
        if transactionToEdit?.isBalanceAdjustment == true { return "Корректировка" }
        if transactionToEdit != nil { return "Редактирование" }
        return kind == .expense ? "Новый расход" : "Новый доход"
    }
}

#Preview("Новая операция") {
    NewTransactionView()
        .modelContainer(BalanceModelContainer.previewContainer)
}

#Preview("Редактирование операции") {
    NewTransactionView(
        transaction: FinanceTransaction(
            amount: 2_450,
            date: .now,
            note: "Пятёрочка у дома",
            categoryName: "Продукты",
            categoryIcon: "cart.fill",
            kind: .expense
        )
    )
    .modelContainer(BalanceModelContainer.previewContainer)
}
