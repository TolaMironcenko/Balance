import Charts
import Foundation
import SwiftData
import SwiftUI

private enum MacAnalyticsPeriod: String, CaseIterable, Identifiable {
    case month
    case threeMonths
    case year

    var id: String { rawValue }
    var title: String {
        switch self {
        case .month: "Месяц"
        case .threeMonths: "3 месяца"
        case .year: "12 месяцев"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .month: .day
        case .threeMonths: .weekOfYear
        case .year: .month
        }
    }

    func interval(now: Date = .now) -> DateInterval {
        let calendar = Calendar.current
        let current = calendar.dateInterval(of: .month, for: now)
            ?? DateInterval(start: now, duration: 30 * 86_400)
        let offset = self == .month ? 0 : (self == .threeMonths ? -2 : -11)
        let start = calendar.date(byAdding: .month, value: offset, to: current.start)
            ?? current.start
        return DateInterval(start: start, end: current.end)
    }
}

private struct MacCashPoint: Identifiable {
    let date: Date
    let kind: TransactionKind
    let amount: Double
    var id: String { "\(date.timeIntervalSince1970)-\(kind.rawValue)" }
}

struct MacAnalyticsView: View {
    @Query private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var period = MacAnalyticsPeriod.month

    private var interval: DateInterval { period.interval() }
    private var summary: FinancePeriodSummary {
        FinanceCalculations.summary(transactions: transactions, in: interval)
    }
    private var spending: [CategorySpending] {
        Array(FinanceCalculations.spendingByCategory(
            transactions: transactions,
            in: interval
        ).prefix(8))
    }
    private var savingsRate: Double {
        summary.income > 0 ? summary.balance / summary.income * 100 : 0
    }
    private var cashPoints: [MacCashPoint] {
        let calendar = Calendar.current
        let filtered = transactions.filter {
            interval.contains($0.date) && !$0.isBalanceAdjustment
        }
        let grouped = Dictionary(grouping: filtered) { transaction in
            let date = calendar.dateInterval(of: period.component, for: transaction.date)?.start
                ?? transaction.date
            return "\(date.timeIntervalSince1970)|\(transaction.kind.rawValue)"
        }
        return grouped.compactMap { _, values in
            guard let first = values.first else { return nil }
            let date = calendar.dateInterval(of: period.component, for: first.date)?.start
                ?? first.date
            return MacCashPoint(
                date: date,
                kind: first.kind,
                amount: values.reduce(0) { $0 + $1.amount }
            )
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("Аналитика")
                        .font(.largeTitle.bold())
                    Spacer()
                    Picker("Период", selection: $period) {
                        ForEach(MacAnalyticsPeriod.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 330)
                }

                HStack(spacing: 14) {
                    metric("Доходы", summary.income.formattedCurrency(code: currencyCode), .green)
                    metric("Расходы", summary.expenses.formattedCurrency(code: currencyCode), .red)
                    metric("Результат", summary.balance.formattedCurrency(code: currencyCode), .indigo)
                    metric("Сбережения", savingsRate.formatted(.number.precision(.fractionLength(0))) + "%", .teal)
                }

                HStack(alignment: .top, spacing: 18) {
                    GroupBox("Динамика доходов и расходов") {
                        if cashPoints.isEmpty {
                            ContentUnavailableView("Нет данных", systemImage: "chart.xyaxis.line")
                                .frame(height: 280)
                        } else {
                            Chart(cashPoints) { point in
                                LineMark(
                                    x: .value("Дата", point.date),
                                    y: .value("Сумма", point.amount)
                                )
                                .foregroundStyle(by: .value("Тип", point.kind.title))
                                .interpolationMethod(.catmullRom)
                                PointMark(
                                    x: .value("Дата", point.date),
                                    y: .value("Сумма", point.amount)
                                )
                                .foregroundStyle(by: .value("Тип", point.kind.title))
                            }
                            .chartForegroundStyleScale([
                                TransactionKind.income.title: Color.green,
                                TransactionKind.expense.title: Color.red
                            ])
                            .frame(height: 280)
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)

                    GroupBox("Структура расходов") {
                        if spending.isEmpty {
                            ContentUnavailableView("Нет расходов", systemImage: "chart.pie")
                                .frame(height: 280)
                        } else {
                            Chart(spending) { item in
                                SectorMark(
                                    angle: .value("Сумма", item.amount),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(tint(for: item))
                            }
                            .frame(height: 280)
                            .padding()
                        }
                    }
                    .frame(width: 360)
                }
            }
            .padding(28)
        }
    }

    private func metric(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(tint)
            Text(value).font(.title3.bold()).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private func tint(for item: CategorySpending) -> Color {
        item.colorName == "auto"
            ? FinanceCategory.find(named: item.name)?.tint ?? .indigo
            : FinanceCategory.color(named: item.colorName)
    }
}

#Preview("Аналитика") {
    MacAnalyticsView()
        .modelContainer(BalanceModelContainer.previewContainer)
        .frame(width: 1000, height: 700)
}

struct MacBalanceAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var desiredBalance = 0.0
    @State private var note = ""

    private var current: Double {
        FinanceCalculations.totalBalance(transactions: transactions)
    }
    private var difference: Double { desiredBalance - current }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Корректировка баланса").font(.title.bold())
            LabeledContent("Расчётный баланс", value: current.formattedCurrency(code: currencyCode))
            TextField("Фактический баланс", value: $desiredBalance, format: .number)
            if abs(difference) >= 0.005 {
                LabeledContent(
                    difference > 0 ? "Добавится доход" : "Добавится расход",
                    value: abs(difference).formattedCurrency(code: currencyCode)
                )
            }
            TextField("Комментарий", text: $note)
            Text("Корректировка изменяет общий баланс, но не влияет на аналитику.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                Button("Сохранить", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(abs(difference) < 0.005)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear { desiredBalance = current }
    }

    private func save() {
        guard abs(difference) >= 0.005 else { return }
        modelContext.insert(FinanceTransaction(
            amount: abs(difference),
            note: note.isEmpty ? "Ручная корректировка баланса" : note,
            categoryName: "Корректировка",
            categoryIcon: "slider.horizontal.3",
            categoryColorName: "indigo",
            isBalanceAdjustment: true,
            kind: difference > 0 ? .income : .expense
        ))
        dismiss()
    }
}

#Preview("Корректировка баланса") {
    MacBalanceAdjustmentView()
        .modelContainer(BalanceModelContainer.previewContainer)
}

struct MacBudgetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.createdAt) private var customCategories: [CustomCategory]
    let budgets: [MonthlyBudget]
    let monthStart: Date
    @State private var limits: [String: Double]

    init(budgets: [MonthlyBudget], monthStart: Date) {
        self.budgets = budgets
        self.monthStart = monthStart
        _limits = State(initialValue: Dictionary(uniqueKeysWithValues: budgets.map {
            ($0.categoryName, $0.limit)
        }))
    }

    private var categories: [FinanceCategory] {
        FinanceCategory.expenseCategories
            + customCategories.filter { $0.kind == .expense }.map(\.financeCategory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Месячные лимиты").font(.title.bold())
            List(categories) { category in
                HStack {
                    CategoryIconView(
                        systemName: category.icon,
                        emoji: category.emoji,
                        tint: category.tint,
                        size: 16
                    )
                    Text(category.name)
                    Spacer()
                    TextField("0", value: binding(for: category.name), format: .number)
                        .frame(width: 120)
                }
            }
            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                Button("Сохранить", action: save).buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 520, height: 600)
    }

    private func binding(for name: String) -> Binding<Double> {
        Binding(get: { limits[name, default: 0] }, set: { limits[name] = max(0, $0) })
    }

    private func save() {
        for category in categories {
            let value = limits[category.name, default: 0]
            let existing = budgets.first { $0.categoryName == category.name }
            if value > 0 {
                if let existing {
                    existing.limit = value
                    existing.categoryIcon = category.icon
                    existing.categoryEmoji = category.emoji
                    existing.syncUpdatedAt = .now
                } else {
                    modelContext.insert(MonthlyBudget(
                        categoryName: category.name,
                        categoryIcon: category.icon,
                        categoryEmoji: category.emoji,
                        limit: value,
                        monthStart: monthStart
                    ))
                }
            } else if let existing {
                modelContext.deleteForSync(existing)
            }
        }
        dismiss()
    }
}

#Preview("Лимиты") {
    MacBudgetEditor(
        budgets: [
            MonthlyBudget(
                categoryName: "Продукты",
                categoryIcon: "cart.fill",
                limit: 30_000,
                monthStart: .now
            ),
            MonthlyBudget(
                categoryName: "Транспорт",
                categoryIcon: "car.fill",
                limit: 8_000,
                monthStart: .now
            )
        ],
        monthStart: FinanceCalculations.monthInterval(containing: .now).start
    )
    .modelContainer(BalanceModelContainer.previewContainer)
}

struct MacSettingsView: View {
    @Query private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue

    private var exportDocument: CSVDocument {
        CSVDocument(transactions: transactions)
    }

    var body: some View {
        Form {
            Section("Отображение") {
                Picker("Валюта", selection: $currencyCode) {
                    ForEach(SupportedCurrency.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("Тема", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { Text($0.title).tag($0.rawValue) }
                }
            }
            Section("Данные") {
                NavigationLink {
                    ServerAccountView()
                } label: {
                    Label("Сервер и синхронизация", systemImage: "server.rack")
                }
                ShareLink(item: exportDocument, preview: SharePreview(
                    "Операции",
                    image: Image(systemName: "tablecells")
                )) {
                    Label("Экспортировать CSV", systemImage: "square.and.arrow.up")
                }
                .disabled(transactions.isEmpty)
                LabeledContent("Операций", value: transactions.count.formatted())
            }
            Section("Хранение") {
                Label(
                    BalanceModelContainer.isCloudSyncEnabled
                        ? "Синхронизация CloudKit включена"
                        : "Локальный режим для Personal Team",
                    systemImage: BalanceModelContainer.isCloudSyncEnabled ? "icloud.fill" : "internaldrive.fill"
                )
            }
            Section {
                LabeledContent("Версия", value: "3.1.1")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Настройки")
        .padding(24)
    }
}

#Preview("Настройки") {
    NavigationStack {
        MacSettingsView()
    }
    .modelContainer(BalanceModelContainer.previewContainer)
    .frame(width: 640, height: 640)
}
