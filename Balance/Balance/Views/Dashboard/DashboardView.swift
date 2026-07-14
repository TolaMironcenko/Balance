import Charts
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \FinanceTransaction.date, order: .reverse)
    private var transactions: [FinanceTransaction]

    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var showingNewTransaction = false
    @State private var showingBalanceAdjustment = false
    @State private var editingTransaction: FinanceTransaction?

    private var monthInterval: DateInterval {
        FinanceCalculations.monthInterval(containing: .now)
    }

    private var summary: FinancePeriodSummary {
        FinanceCalculations.summary(transactions: transactions, in: monthInterval)
    }

    private var totalBalance: Double {
        FinanceCalculations.totalBalance(transactions: transactions)
    }

    private var categorySpending: [CategorySpending] {
        Array(
            FinanceCalculations
                .spendingByCategory(transactions: transactions, in: monthInterval)
                .prefix(5)
        )
    }

    private var recentTransactions: [FinanceTransaction] {
        Array(transactions.prefix(4))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    balanceHero
                    summaryGrid
                    spendingSection
                    recentSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Обзор")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingNewTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Добавить операцию")

                    Menu {
                        Button {
                            showingBalanceAdjustment = true
                        } label: {
                            Label("Скорректировать баланс", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingNewTransaction) {
                NewTransactionView()
            }
            .sheet(isPresented: $showingBalanceAdjustment) {
                BalanceAdjustmentView()
            }
            .sheet(item: $editingTransaction) { transaction in
                NewTransactionView(transaction: transaction)
            }
        }
    }

    private var balanceHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Текущий момент", systemImage: "creditcard.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.white.opacity(0.75))
            }

            Text("Общий баланс")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
            Text(totalBalance.formattedCurrency(code: currencyCode))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Button {
                showingBalanceAdjustment = true
            } label: {
                Label("Скорректировать", systemImage: "slider.horizontal.3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.16), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .shadow(color: .indigo.opacity(0.25), radius: 18, y: 9)
    }

    private var summaryGrid: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Доходы",
                amount: summary.income,
                currencyCode: currencyCode,
                icon: "arrow.down.left",
                tint: .green
            )
            SummaryCard(
                title: "Расходы",
                amount: summary.expenses,
                currencyCode: currencyCode,
                icon: "arrow.up.right",
                tint: .red
            )
        }
    }

    @ViewBuilder
    private var spendingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Расходы по категориям")
                .font(.title3.bold())

            if categorySpending.isEmpty {
                EmptyStateCard(
                    icon: "chart.bar.xaxis",
                    title: "Пока нет расходов",
                    message: "Добавьте первую операцию — здесь появится аналитика за месяц."
                )
            } else {
                Chart(categorySpending) { item in
                    BarMark(
                        x: .value("Сумма", item.amount),
                        y: .value("Категория", item.name)
                    )
                    .foregroundStyle(tint(for: item))
                    .cornerRadius(5)
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(categorySpending.count * 44 + 20))
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Последние операции")
                .font(.title3.bold())

            if recentTransactions.isEmpty {
                EmptyStateCard(
                    icon: "tray",
                    title: "История пуста",
                    message: "Доходы и расходы будут собраны здесь."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(recentTransactions) { transaction in
                        TransactionRow(transaction: transaction, currencyCode: currencyCode)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingTransaction = transaction
                            }
                        if transaction.id != recentTransactions.last?.id {
                            Divider().padding(.leading, 54)
                        }
                    }
                }
                .padding(.horizontal)
                .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func tint(for item: CategorySpending) -> Color {
        if item.colorName == "auto" {
            return FinanceCategory.find(named: item.name)?.tint ?? .indigo
        }
        return FinanceCategory.color(named: item.colorName)
    }
}
