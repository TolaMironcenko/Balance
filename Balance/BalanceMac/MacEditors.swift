import SwiftData
import SwiftUI

struct MacTransactionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]

    private let transaction: FinanceTransaction?
    @State private var kind: TransactionKind
    @State private var amount: Double
    @State private var categoryName: String
    @State private var date: Date
    @State private var note: String

    init(transaction: FinanceTransaction? = nil) {
        self.transaction = transaction
        let kind = transaction?.kind ?? .expense
        _kind = State(initialValue: kind)
        _amount = State(initialValue: transaction?.amount ?? 0)
        _categoryName = State(initialValue: transaction?.categoryName
            ?? FinanceCategory.categories(for: kind)[0].name)
        _date = State(initialValue: transaction?.date ?? .now)
        _note = State(initialValue: transaction?.note ?? "")
    }

    private var categories: [FinanceCategory] {
        var values = FinanceCategory.categories(for: kind)
            + customCategories.filter { $0.kind == kind }.map(\.financeCategory)
        if let transaction,
           !values.contains(where: { $0.name == transaction.categoryName }) {
            values.append(FinanceCategory(
                id: "archived-\(transaction.id)",
                name: transaction.categoryName,
                icon: transaction.categoryIcon,
                emoji: transaction.categoryEmoji,
                colorName: transaction.categoryColorName
            ))
        }
        return values
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(transaction == nil ? "Новая операция" : "Редактирование операции")
                .font(.title.bold())

            Picker("Тип", selection: $kind) {
                ForEach(TransactionKind.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(transaction?.isBalanceAdjustment == true)
            .onChange(of: kind) { _, newKind in
                categoryName = FinanceCategory.categories(for: newKind)[0].name
            }

            TextField("Сумма", value: $amount, format: .number)

            Picker("Категория", selection: $categoryName) {
                ForEach(categories) { Text($0.name).tag($0.name) }
            }
            .disabled(transaction?.isBalanceAdjustment == true)

            DatePicker("Дата", selection: $date, displayedComponents: .date)
            TextField("Заметка", text: $note)

            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                Button("Сохранить", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(amount <= 0)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func save() {
        guard amount > 0 else { return }
        let category = categories.first { $0.name == categoryName }
            ?? FinanceCategory.categories(for: kind)[0]
        if let transaction {
            transaction.amount = amount
            transaction.kind = kind
            transaction.categoryName = category.name
            transaction.categoryIcon = category.icon
            transaction.categoryEmoji = category.emoji
            transaction.categoryColorName = category.colorName
            transaction.date = date
            transaction.note = note
            transaction.syncUpdatedAt = .now
        } else {
            modelContext.insert(FinanceTransaction(
                amount: amount,
                date: date,
                note: note,
                categoryName: category.name,
                categoryIcon: category.icon,
                categoryEmoji: category.emoji,
                categoryColorName: category.colorName,
                kind: kind
            ))
        }
        dismiss()
    }
}

struct MacCategoryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [FinanceTransaction]
    @Query private var budgets: [MonthlyBudget]
    @Query private var customCategories: [CustomCategory]

    private let category: CustomCategory?
    @State private var name: String
    @State private var kind: TransactionKind
    @State private var emoji: String
    @State private var icon: String
    @State private var colorName: String
    @State private var usesEmoji: Bool

    init(category: CustomCategory? = nil) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _kind = State(initialValue: category?.kind ?? .expense)
        _emoji = State(initialValue: category?.emoji ?? "")
        _icon = State(initialValue: category?.icon ?? "star.fill")
        _colorName = State(initialValue: category?.colorName ?? "indigo")
        _usesEmoji = State(initialValue: category?.emoji.isEmpty == false)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        let names = (FinanceCategory.expenseCategories + FinanceCategory.incomeCategories).map(\.name)
            + customCategories.filter { $0.id != category?.id }.map(\.name)
        return names.contains {
            $0.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(category == nil ? "Новая категория" : "Редактирование категории")
                .font(.title.bold())
            TextField("Название", text: $name)
            if isDuplicate && !trimmedName.isEmpty {
                Text("Категория с таким названием уже существует")
                    .font(.caption).foregroundStyle(.red)
            }
            Picker("Тип", selection: $kind) {
                ForEach(TransactionKind.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(category != nil)
            Picker("Оформление", selection: $usesEmoji) {
                Text("Иконка").tag(false)
                Text("Эмодзи").tag(true)
            }
            .pickerStyle(.segmented)
            if usesEmoji {
                TextField("Своё эмодзи", text: $emoji)
                Picker("Готовое эмодзи", selection: $emoji) {
                    ForEach(CategoryDesignOptions.emojis, id: \.self) { Text($0).tag($0) }
                }
            } else {
                Picker("Иконка", selection: $icon) {
                    ForEach(CategoryDesignOptions.icons, id: \.self) { value in
                        Label(value, systemImage: value).tag(value)
                    }
                }
            }
            Picker("Цвет", selection: $colorName) {
                ForEach(CategoryDesignOptions.colors, id: \.self) { value in
                    HStack {
                        Circle().fill(FinanceCategory.color(named: value)).frame(width: 10, height: 10)
                        Text(value.capitalized)
                    }
                    .tag(value)
                }
            }
            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                Button("Сохранить", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedName.isEmpty || isDuplicate)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        let oneEmoji = usesEmoji ? emoji.first.map(String.init) ?? "" : ""
        if let category {
            let oldName = category.name
            category.name = trimmedName
            category.icon = icon.isEmpty ? "star.fill" : icon
            category.emoji = oneEmoji
            category.colorName = colorName
            category.syncUpdatedAt = .now
            transactions.filter { $0.categoryName == oldName }.forEach {
                $0.categoryName = trimmedName
                $0.categoryIcon = category.icon
                $0.categoryEmoji = oneEmoji
                $0.categoryColorName = colorName
                $0.syncUpdatedAt = .now
            }
            budgets.filter { $0.categoryName == oldName }.forEach {
                $0.categoryName = trimmedName
                $0.categoryIcon = category.icon
                $0.categoryEmoji = oneEmoji
                $0.syncUpdatedAt = .now
            }
        } else {
            modelContext.insert(CustomCategory(
                name: trimmedName,
                icon: icon.isEmpty ? "star.fill" : icon,
                emoji: oneEmoji,
                colorName: colorName,
                kind: kind
            ))
        }
        dismiss()
    }
}
