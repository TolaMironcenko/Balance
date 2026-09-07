import Charts
import SwiftData
import SwiftUI

private enum MacSection: String, CaseIterable, Identifiable {
    case overview
    case analytics
    case transactions
    case budgets
    case categories
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Обзор"
        case .analytics: "Аналитика"
        case .transactions: "Операции"
        case .budgets: "Бюджеты"
        case .categories: "Категории"
        case .settings: "Настройки"
        }
    }

    var icon: String {
        switch self {
        case .overview: "chart.pie.fill"
        case .analytics: "chart.xyaxis.line"
        case .transactions: "list.bullet.rectangle"
        case .budgets: "target"
        case .categories: "square.grid.2x2"
        case .settings: "gearshape.fill"
        }
    }
}

struct MacContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: MacSection? = .overview

    var body: some View {
        NavigationSplitView {
            List(MacSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("Баланс")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            switch selection ?? .overview {
            case .overview:
                MacOverviewView()
            case .analytics:
                MacAnalyticsView()
            case .transactions:
                MacTransactionsView()
            case .budgets:
                MacBudgetsView()
            case .categories:
                MacCategoriesView()
            case .settings:
                NavigationStack {
                    MacSettingsView()
                }
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

private struct MacOverviewView: View {
    @Query(sort: \FinanceTransaction.date, order: .reverse)
    private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var showingBalanceAdjustment = false

    private var interval: DateInterval {
        FinanceCalculations.monthInterval(containing: .now)
    }

    private var summary: FinancePeriodSummary {
        FinanceCalculations.summary(transactions: transactions, in: interval)
    }

    private var spending: [CategorySpending] {
        Array(FinanceCalculations.spendingByCategory(
            transactions: transactions,
            in: interval
        ).prefix(8))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Обзор")
                        .font(.largeTitle.bold())
                    Spacer()
                    Button {
                        showingBalanceAdjustment = true
                    } label: {
                        Label("Скорректировать баланс", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 14) {
                    MacMetricCard(
                        title: "Общий баланс",
                        value: FinanceCalculations.totalBalance(transactions: transactions)
                            .formattedCurrency(code: currencyCode),
                        icon: "creditcard.fill",
                        tint: .indigo
                    )
                    MacMetricCard(
                        title: "Доходы за месяц",
                        value: summary.income.formattedCurrency(code: currencyCode),
                        icon: "arrow.down.left",
                        tint: .green
                    )
                    MacMetricCard(
                        title: "Расходы за месяц",
                        value: summary.expenses.formattedCurrency(code: currencyCode),
                        icon: "arrow.up.right",
                        tint: .red
                    )
                }

                GroupBox("Расходы по категориям") {
                    if spending.isEmpty {
                        ContentUnavailableView(
                            "Нет данных",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Добавьте операции на iPhone, Mac или Apple Watch.")
                        )
                        .frame(height: 260)
                    } else {
                        Chart(spending) { item in
                            BarMark(
                                x: .value("Категория", item.name),
                                y: .value("Сумма", item.amount)
                            )
                            .foregroundStyle(tint(for: item))
                            .cornerRadius(5)
                        }
                        .frame(height: 300)
                        .padding()
                    }
                }
            }
            .padding(28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingBalanceAdjustment) {
            MacBalanceAdjustmentView()
        }
    }

    private func tint(for item: CategorySpending) -> Color {
        if item.colorName == "auto" {
            return FinanceCategory.find(named: item.name)?.tint ?? .indigo
        }
        return FinanceCategory.color(named: item.colorName)
    }
}

private struct MacMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

private struct MacTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FinanceTransaction.date, order: .reverse)
    private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var searchText = ""
    @State private var selectedKind: TransactionKind?
    @State private var showingNewTransaction = false
    @State private var editingTransaction: FinanceTransaction?

    private var filtered: [FinanceTransaction] {
        transactions.filter {
            (selectedKind == nil || $0.kind == selectedKind)
                && (searchText.isEmpty
                || $0.categoryName.localizedCaseInsensitiveContains(searchText)
                || $0.note.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Операции")
                    .font(.largeTitle.bold())
                Picker("Тип", selection: $selectedKind) {
                    Text("Все").tag(TransactionKind?.none)
                    Text("Расходы").tag(TransactionKind?.some(.expense))
                    Text("Доходы").tag(TransactionKind?.some(.income))
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                Spacer()
                Button {
                    showingNewTransaction = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)

            if filtered.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "Нет операций" : "Ничего не найдено",
                    systemImage: "list.bullet.rectangle"
                )
            } else {
                List(filtered) { transaction in
                    Button {
                        editingTransaction = transaction
                    } label: {
                        HStack(spacing: 12) {
                            CategoryIconView(
                                systemName: transaction.categoryIcon,
                                emoji: transaction.categoryEmoji,
                                tint: transactionTint(transaction),
                                size: transaction.categoryEmoji.isEmpty ? 15 : 20,
                                containerSize: 38
                            )
                            VStack(alignment: .leading, spacing: 3) {
                                Text(transaction.categoryName)
                                    .font(.headline)
                                Text(transaction.note.isEmpty
                                    ? transaction.date.formatted(date: .abbreviated, time: .omitted)
                                    : transaction.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text((transaction.kind == .income ? "+" : "−")
                                + transaction.amount.formattedCurrency(code: currencyCode))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(transaction.kind == .income ? .green : .primary)
                        }
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Редактировать") { editingTransaction = transaction }
                        Button("Удалить", role: .destructive) {
                            modelContext.deleteForSync(transaction)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Категория или заметка")
        .sheet(isPresented: $showingNewTransaction) {
            MacTransactionEditor()
        }
        .sheet(item: $editingTransaction) { transaction in
            MacTransactionEditor(transaction: transaction)
        }
    }

    private func transactionTint(_ transaction: FinanceTransaction) -> Color {
        if transaction.categoryColorName == "auto" {
            return FinanceCategory.find(named: transaction.categoryName)?.tint ?? .indigo
        }
        return FinanceCategory.color(named: transaction.categoryColorName)
    }
}

private struct MacBudgetsView: View {
    @Query private var budgets: [MonthlyBudget]
    @Query private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var showingEditor = false

    private var interval: DateInterval {
        FinanceCalculations.monthInterval(containing: .now)
    }

    private var currentBudgets: [MonthlyBudget] {
        budgets.filter { interval.contains($0.monthStart) }
    }

    private var spending: [String: Double] {
        Dictionary(uniqueKeysWithValues: FinanceCalculations.spendingByCategory(
            transactions: transactions,
            in: interval
        ).map { ($0.name, $0.amount) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Бюджеты")
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    showingEditor = true
                } label: {
                    Label("Изменить лимиты", systemImage: "pencil")
                }
                .buttonStyle(.borderedProminent)
            }

            if currentBudgets.isEmpty {
                ContentUnavailableView(
                    "Бюджеты не заданы",
                    systemImage: "target",
                    description: Text("Настройте лимиты на iPhone — они появятся здесь через iCloud.")
                )
            } else {
                List(currentBudgets) { budget in
                    let spent = spending[budget.categoryName, default: 0]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            CategoryIconView(
                                systemName: budget.categoryIcon,
                                emoji: budget.categoryEmoji,
                                tint: .indigo,
                                size: 17
                            )
                            Text(budget.categoryName).font(.headline)
                            Spacer()
                            Text("\(spent.formattedCurrency(code: currencyCode)) из \(budget.limit.formattedCurrency(code: currencyCode))")
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: min(budget.limit > 0 ? spent / budget.limit : 0, 1))
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(24)
        .sheet(isPresented: $showingEditor) {
            MacBudgetEditor(budgets: currentBudgets, monthStart: interval.start)
        }
    }
}

private struct MacCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.createdAt)
    private var categories: [CustomCategory]
    @Query private var budgets: [MonthlyBudget]
    @State private var showingNewCategory = false
    @State private var editingCategory: CustomCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Категории")
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    showingNewCategory = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if categories.isEmpty {
                ContentUnavailableView(
                    "Нет собственных категорий",
                    systemImage: "square.grid.2x2"
                )
            } else {
                List(categories) { category in
                    Button {
                        editingCategory = category
                    } label: {
                        HStack {
                            CategoryIconView(
                                systemName: category.icon,
                                emoji: category.emoji,
                                tint: FinanceCategory.color(named: category.colorName),
                                size: category.emoji.isEmpty ? 16 : 20,
                                containerSize: 36
                            )
                            Text(category.name)
                            Spacer()
                            Text(category.kind.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Редактировать") { editingCategory = category }
                        Button("Удалить", role: .destructive) {
                            budgets.filter { $0.categoryName == category.name }
                                .forEach { modelContext.deleteForSync($0) }
                            modelContext.deleteForSync(category)
                        }
                    }
                }
            }
        }
        .padding(24)
        .sheet(isPresented: $showingNewCategory) {
            MacCategoryEditor()
        }
        .sheet(item: $editingCategory) { category in
            MacCategoryEditor(category: category)
        }
    }
}

#Preview("Главное окно") {
    MacContentView()
        .modelContainer(BalanceModelContainer.previewContainer)
}

#Preview("Обзор") {
    MacOverviewView()
        .modelContainer(BalanceModelContainer.previewContainer)
        .frame(width: 900, height: 620)
}

#Preview("Карточки метрик") {
    HStack(spacing: 14) {
        MacMetricCard(
            title: "Общий баланс",
            value: "62 700 ₽",
            icon: "creditcard.fill",
            tint: .indigo
        )
        MacMetricCard(
            title: "Доходы за месяц",
            value: "150 000 ₽",
            icon: "arrow.down.left",
            tint: .green
        )
        MacMetricCard(
            title: "Расходы за месяц",
            value: "87 300 ₽",
            icon: "arrow.up.right",
            tint: .red
        )
    }
    .padding()
    .frame(width: 720)
}

#Preview("Операции") {
    MacTransactionsView()
        .modelContainer(BalanceModelContainer.previewContainer)
        .frame(width: 900, height: 620)
}

#Preview("Бюджеты") {
    MacBudgetsView()
        .modelContainer(BalanceModelContainer.previewContainer)
        .frame(width: 900, height: 620)
}

#Preview("Категории") {
    MacCategoriesView()
        .modelContainer(BalanceModelContainer.previewContainer)
        .frame(width: 900, height: 620)
}
