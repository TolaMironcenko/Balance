import Charts
import SwiftData
import SwiftUI

private enum AnalyticsPeriod: String, CaseIterable, Identifiable {
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

    func interval(now: Date = .now, calendar: Calendar = .current) -> DateInterval {
        let currentMonth = calendar.dateInterval(of: .month, for: now)
            ?? DateInterval(start: now, duration: 30 * 24 * 60 * 60)
        let start: Date

        switch self {
        case .month:
            start = currentMonth.start
        case .threeMonths:
            start = calendar.date(byAdding: .month, value: -2, to: currentMonth.start)
                ?? currentMonth.start
        case .year:
            start = calendar.date(byAdding: .month, value: -11, to: currentMonth.start)
                ?? currentMonth.start
        }

        return DateInterval(start: start, end: currentMonth.end)
    }

    var bucketComponent: Calendar.Component {
        switch self {
        case .month: .day
        case .threeMonths: .weekOfYear
        case .year: .month
        }
    }

    var axisDateFormat: Date.FormatStyle {
        switch self {
        case .month:
            .dateTime.day().month(.abbreviated)
        case .threeMonths:
            .dateTime.day().month(.abbreviated)
        case .year:
            .dateTime.month(.abbreviated)
        }
    }
}

private struct CashFlowBucketKey: Hashable {
    let date: Date
    let kind: TransactionKind
}

private struct CashFlowPoint: Identifiable {
    let date: Date
    let kind: TransactionKind
    let amount: Double

    var id: String { "\(date.timeIntervalSince1970)-\(kind.rawValue)" }
}

struct AnalyticsView: View {
    @Query private var transactions: [FinanceTransaction]
    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var period = AnalyticsPeriod.month

    private var interval: DateInterval { period.interval() }

    private var periodTransactions: [FinanceTransaction] {
        transactions.filter {
            interval.contains($0.date) && !$0.isBalanceAdjustment
        }
    }

    private var summary: FinancePeriodSummary {
        FinanceCalculations.summary(transactions: transactions, in: interval)
    }

    private var categorySpending: [CategorySpending] {
        Array(
            FinanceCalculations
                .spendingByCategory(transactions: transactions, in: interval)
                .prefix(6)
        )
    }

    private var savingsRate: Double {
        guard summary.income > 0 else { return 0 }
        return summary.balance / summary.income * 100
    }

    private var averageDailyExpense: Double {
        let end = min(Date.now, interval.end)
        let days = max(
            1,
            (Calendar.current.dateComponents([.day], from: interval.start, to: end).day ?? 0) + 1
        )
        return summary.expenses / Double(days)
    }

    private var cashFlowPoints: [CashFlowPoint] {
        let calendar = Calendar.current
        var buckets: [CashFlowBucketKey: Double] = [:]

        for transaction in periodTransactions {
            let bucketDate = calendar.dateInterval(
                of: period.bucketComponent,
                for: transaction.date
            )?.start ?? transaction.date
            let key = CashFlowBucketKey(date: bucketDate, kind: transaction.kind)
            buckets[key, default: 0] += transaction.amount
        }

        return buckets.map { key, amount in
            CashFlowPoint(date: key.date, kind: key.kind, amount: amount)
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    Picker("Период", selection: $period) {
                        ForEach(AnalyticsPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    if periodTransactions.isEmpty {
                        EmptyStateCard(
                            icon: "chart.xyaxis.line",
                            title: "Недостаточно данных",
                            message: "Добавьте операции за выбранный период, чтобы увидеть аналитику."
                        )
                    } else {
                        metricsGrid
                        cashFlowSection
                        categorySection
                        insightsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Аналитика")
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            AnalyticsMetricCard(
                title: "Доходы",
                value: summary.income.formattedCurrency(code: currencyCode),
                icon: "arrow.down.left",
                tint: .green
            )
            AnalyticsMetricCard(
                title: "Расходы",
                value: summary.expenses.formattedCurrency(code: currencyCode),
                icon: "arrow.up.right",
                tint: .red
            )
            AnalyticsMetricCard(
                title: "Результат",
                value: summary.balance.formattedCurrency(code: currencyCode),
                icon: "equal.circle.fill",
                tint: summary.balance >= 0 ? .indigo : .red
            )
            AnalyticsMetricCard(
                title: "Сбережения",
                value: savingsRate.formatted(.number.precision(.fractionLength(0))) + "%",
                icon: "percent",
                tint: savingsRate >= 0 ? .teal : .red
            )
        }
    }

    private var cashFlowSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Динамика")
                .font(.title3.bold())

            Chart(cashFlowPoints) { point in
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
                .symbolSize(22)
            }
            .chartForegroundStyleScale([
                TransactionKind.income.title: Color.green,
                TransactionKind.expense.title: Color.red
            ])
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: period.axisDateFormat)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 230)
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Структура расходов")
                .font(.title3.bold())

            if categorySpending.isEmpty {
                Text("За выбранный период расходов нет.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .center, spacing: 18) {
                    Chart(categorySpending) { item in
                        SectorMark(
                            angle: .value("Сумма", item.amount),
                            innerRadius: .ratio(0.58),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(tint(for: item))
                    }
                    .frame(width: 130, height: 130)

                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(categorySpending.prefix(5)) { item in
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(tint(for: item))
                                    .frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text(item.amount.formattedCurrency(code: currencyCode))
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Главное")
                .font(.title3.bold())

            VStack(spacing: 0) {
                insightRow(
                    icon: "calendar",
                    tint: .orange,
                    title: "Средний расход в день",
                    value: averageDailyExpense.formattedCurrency(code: currencyCode)
                )

                if let largestCategory = categorySpending.first {
                    Divider().padding(.leading, 54)
                    insightRow(
                        icon: largestCategory.icon,
                        emoji: largestCategory.emoji,
                        tint: tint(for: largestCategory),
                        title: "Крупнейшая категория",
                        value: largestCategory.name
                    )
                }
            }
            .padding(.horizontal)
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func insightRow(
        icon: String,
        emoji: String = "",
        tint: Color,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 12) {
            CategoryIconView(
                systemName: icon,
                emoji: emoji,
                tint: tint,
                size: emoji.isEmpty ? 16 : 20,
                containerSize: 38
            )
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 11)
    }

    private func tint(for item: CategorySpending) -> Color {
        if item.colorName == "auto" {
            return FinanceCategory.find(named: item.name)?.tint ?? .indigo
        }
        return FinanceCategory.color(named: item.colorName)
    }
}

private struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(tint)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
