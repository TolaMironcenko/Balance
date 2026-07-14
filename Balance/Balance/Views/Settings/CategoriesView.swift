import SwiftData
import SwiftUI

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]
    @Query private var budgets: [MonthlyBudget]
    @State private var showingNewCategory = false
    @State private var editingCategory: CustomCategory?

    var body: some View {
        List {
            Section("Собственные") {
                if customCategories.isEmpty {
                    Text("Добавьте категории под свой способ ведения бюджета.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(customCategories) { category in
                        HStack(spacing: 12) {
                            CategoryIconView(
                                systemName: category.icon,
                                emoji: category.emoji,
                                tint: FinanceCategory.color(named: category.colorName),
                                size: category.emoji.isEmpty ? 16 : 21,
                                containerSize: 34
                            )

                            Text(category.name)
                            Spacer()
                            Text(category.kind.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                        }
                    }
                    .onDelete(perform: deleteCategories)
                }
            }

            Section("Встроенные") {
                ForEach(FinanceCategory.expenseCategories + FinanceCategory.incomeCategories) { category in
                    HStack(spacing: 12) {
                        CategoryIconView(
                            systemName: category.icon,
                            emoji: category.emoji,
                            tint: category.tint,
                            size: 16
                        )
                        Text(category.name)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle("Категории")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewCategory = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Добавить категорию")
            }
        }
        .sheet(isPresented: $showingNewCategory) {
            CategoryEditorView()
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category)
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = customCategories[index]
            if category.kind == .expense {
                budgets
                    .filter { $0.categoryName == category.name }
                    .forEach { modelContext.deleteForSync($0) }
            }
            modelContext.deleteForSync(category)
        }
    }
}

private enum CategoryVisualMode: String, CaseIterable, Identifiable {
    case icon
    case emoji

    var id: String { rawValue }
    var title: String { self == .icon ? "Иконка" : "Эмодзи" }
}

private struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var customCategories: [CustomCategory]
    @Query private var transactions: [FinanceTransaction]
    @Query private var budgets: [MonthlyBudget]

    private let categoryToEdit: CustomCategory?

    @State private var name: String
    @State private var kind: TransactionKind
    @State private var selectedIcon: String
    @State private var selectedEmoji: String
    @State private var selectedColor: String
    @State private var visualMode: CategoryVisualMode

    private let icons = CategoryDesignOptions.icons
    private let emojis = CategoryDesignOptions.emojis
    private let colors = CategoryDesignOptions.colors

    init(category: CustomCategory? = nil) {
        categoryToEdit = category
        let existingEmoji = category?.emoji ?? ""
        _name = State(initialValue: category?.name ?? "")
        _kind = State(initialValue: category?.kind ?? .expense)
        _selectedIcon = State(initialValue: category?.icon ?? "star.fill")
        _selectedEmoji = State(initialValue: existingEmoji.isEmpty ? "⭐️" : existingEmoji)
        _selectedColor = State(initialValue: category?.colorName ?? "indigo")
        _visualMode = State(initialValue: existingEmoji.isEmpty ? .icon : .emoji)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        let existingNames = (
            FinanceCategory.expenseCategories
                + FinanceCategory.incomeCategories
        ).map(\.name) + customCategories
            .filter { $0.id != categoryToEdit?.id }
            .map(\.name)
        return existingNames.contains {
            $0.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
            && !isDuplicate
            && (visualMode == .icon || !selectedEmoji.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $name)
                    Picker("Тип", selection: $kind) {
                        ForEach(TransactionKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(categoryToEdit != nil)

                    if categoryToEdit != nil {
                        Text("Тип категории нельзя изменить, чтобы сохранить корректность старых операций.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isDuplicate && !trimmedName.isEmpty {
                        Label("Категория с таким названием уже существует", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Оформление") {
                    HStack(spacing: 12) {
                        CategoryIconView(
                            systemName: selectedIcon,
                            emoji: visualMode == .emoji ? selectedEmoji : "",
                            tint: FinanceCategory.color(named: selectedColor),
                            size: visualMode == .emoji ? 24 : 19,
                            containerSize: 46
                        )
                        Text(trimmedName.isEmpty ? "Предпросмотр категории" : trimmedName)
                            .font(.headline)
                            .foregroundStyle(trimmedName.isEmpty ? .secondary : .primary)
                    }

                    Picker("Вид", selection: $visualMode) {
                        ForEach(CategoryVisualMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if visualMode == .icon {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.body)
                                        .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 42, height: 40)
                                        .background(
                                            selectedIcon == icon
                                                ? FinanceCategory.color(named: selectedColor)
                                                : Color.secondary.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 11)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        TextField("Введите своё эмодзи", text: $selectedEmoji)
                            .font(.title2)
                            .onChange(of: selectedEmoji) { _, newValue in
                                let oneCharacter = newValue.first.map(String.init) ?? ""
                                if newValue != oneCharacter {
                                    selectedEmoji = oneCharacter
                                }
                            }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 38, height: 38)
                                        .background(
                                            selectedEmoji == emoji
                                                ? FinanceCategory.color(named: selectedColor).opacity(0.22)
                                                : Color.secondary.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 10)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Цвет") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        ForEach(colors, id: \.self) { colorName in
                            let color = FinanceCategory.color(named: colorName)
                            Button {
                                selectedColor = colorName
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if selectedColor == colorName {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(categoryToEdit == nil ? "Новая категория" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(categoryToEdit == nil ? "Добавить" : "Готово", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        if let categoryToEdit {
            let previousName = categoryToEdit.name
            categoryToEdit.name = trimmedName
            categoryToEdit.icon = selectedIcon
            categoryToEdit.emoji = visualMode == .emoji ? selectedEmoji : ""
            categoryToEdit.colorName = selectedColor
            categoryToEdit.syncUpdatedAt = .now

            transactions
                .filter { $0.categoryName == previousName && $0.kind == categoryToEdit.kind }
                .forEach { transaction in
                    transaction.categoryName = trimmedName
                    transaction.categoryIcon = selectedIcon
                    transaction.categoryEmoji = visualMode == .emoji ? selectedEmoji : ""
                    transaction.categoryColorName = selectedColor
                    transaction.syncUpdatedAt = .now
                }

            if categoryToEdit.kind == .expense {
                budgets
                    .filter { $0.categoryName == previousName }
                    .forEach { budget in
                        budget.categoryName = trimmedName
                        budget.categoryIcon = selectedIcon
                        budget.categoryEmoji = visualMode == .emoji ? selectedEmoji : ""
                        budget.syncUpdatedAt = .now
                    }
            }
        } else {
            modelContext.insert(
                CustomCategory(
                    name: trimmedName,
                    icon: selectedIcon,
                    emoji: visualMode == .emoji ? selectedEmoji : "",
                    colorName: selectedColor,
                    kind: kind
                )
            )
        }
        dismiss()
    }
}
