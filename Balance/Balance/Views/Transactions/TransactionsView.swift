import SwiftData
import SwiftUI

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FinanceTransaction.date, order: .reverse)
    private var transactions: [FinanceTransaction]

    @AppStorage("currencyCode") private var currencyCode = SupportedCurrency.RUB.rawValue
    @State private var selectedKind: TransactionKind?
    @State private var searchText = ""
    @State private var showingNewTransaction = false
    @State private var editingTransaction: FinanceTransaction?

    private var filteredTransactions: [FinanceTransaction] {
        transactions.filter { transaction in
            let matchesKind = selectedKind == nil || transaction.kind == selectedKind
            let matchesSearch = searchText.isEmpty
                || transaction.categoryName.localizedCaseInsensitiveContains(searchText)
                || transaction.note.localizedCaseInsensitiveContains(searchText)
            return matchesKind && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                Group {
                    if filteredTransactions.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "Нет операций" : "Ничего не найдено",
                            systemImage: searchText.isEmpty ? "list.bullet.rectangle" : "magnifyingglass",
                            description: Text(searchText.isEmpty
                                ? "Добавьте доход или расход, чтобы начать вести бюджет."
                                : "Измените запрос или фильтр.")
                        )
                    } else {
                        List {
                            ForEach(filteredTransactions) { transaction in
                                TransactionRow(transaction: transaction, currencyCode: currencyCode)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingTransaction = transaction
                                    }
                                    .accessibilityHint("Открывает редактирование операции")
                            }
                            .onDelete(perform: deleteTransactions)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Операции")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Категория или заметка")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Добавить операцию")
                }
            }
            .sheet(isPresented: $showingNewTransaction) {
                NewTransactionView()
            }
            .sheet(item: $editingTransaction) { transaction in
                NewTransactionView(transaction: transaction)
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterButton(title: "Все", kind: nil)
            filterButton(title: "Расходы", kind: .expense)
            filterButton(title: "Доходы", kind: .income)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func filterButton(title: String, kind: TransactionKind?) -> some View {
        Button(title) {
            withAnimation { selectedKind = kind }
        }
        .font(.subheadline.weight(.medium))
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(selectedKind == kind ? .indigo : .secondary)
    }

    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.deleteForSync(filteredTransactions[index])
        }
    }
}

#Preview("Операции") {
    TransactionsView()
        .modelContainer(BalanceModelContainer.previewContainer)
}
